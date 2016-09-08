#!/bin/bash -l

DBNAME="palette"
SCHEMA="palette"
LOGFILE="/var/log/insight-toolkit/db_maintenance.log"

echo "Start maintenance $(date)" > $LOGFILE
echo "Start vacuum analyze pg_catalog tables $(date)" >> $LOGFILE

psql -tc "select 'VACUUM ANALYZE ' || b.nspname || '.' || relname || ';'
from
        pg_class a,
        pg_namespace b
where
        a.relnamespace = b.oid and
        b.nspname in ('pg_catalog') and
        a.relkind='r'" $DBNAME | psql -a $DBNAME >> $LOGFILE 2>&1

echo "End vacuum analyze pg_catalog tables $(date)" >> $LOGFILE

echo "Start set connection limit for readonly to 0 $(date)" >> $LOGFILE
psql $DBNAME -c "alter role readonly with CONNECTION LIMIT 0" >> $LOGFILE 2>&1
echo "End set connection limit for readonly to 0 $(date)" >> $LOGFILE

echo "Start terminate readonly connections $(date)" >> $LOGFILE

psql -tc "select 'select pg_terminate_backend(' || procpid || ');'
from
        pg_stat_activity
where
        datname = '$SCHEMA' and
        usename = 'readonly'" $DBNAME | psql -a $DBNAME >> $LOGFILE 2>&1

echo "End terminate readonly connections $(date)" >> $LOGFILE


echo "Start drop old partitions. " $(date) >> $LOGFILE

psql -tc "select
                        drop_stmt
                from
                        (
                        select
                                'alter table ' || schemaname || '.' || tablename || ' drop partition \"' || partitionname || '\";' drop_stmt,
                                row_number() over (partition by tablename order by partitionname desc) as rn
                        from pg_partitions t
                        where
                                schemaname = '$SCHEMA' and
                                tablename in ('plainlogs', 'threadinfo', 'serverlogs', 'p_threadinfo', 'p_serverlogs', 'p_cpu_usage', 'p_cpu_usage_report') and
                                partitiontype = 'range' and
                                partitionname <> '10010101'
                        ) a
                where
                        rn > 15
                order by 1
        " $DBNAME | psql -a $DBNAME >> $LOGFILE 2>&1

echo "End drop old partitions. " + $(date) >> $LOGFILE


echo "Start drop indexes $(date)" >> $LOGFILE

psql $DBNAME >> $LOGFILE 2>&1 <<EOF
\set ON_ERROR_STOP on
set search_path = $SCHEMA;
begin;
select drop_child_indexes('$SCHEMA.p_cpu_usage_bootstrap_rpt_parent_vizql_session_idx');
select drop_child_indexes('$SCHEMA.p_cpu_usage_report_cpu_usage_parent_vizql_session_idx');
select drop_child_indexes('$SCHEMA.p_serverlogs_p_id_idx');
select drop_child_indexes('$SCHEMA.p_serverlogs_parent_vizql_session_idx');
select drop_child_indexes('$SCHEMA.p_serverlogs_bootstrap_rpt_parent_vizql_session_idx');

drop index p_cpu_usage_bootstrap_rpt_parent_vizql_session_idx;
drop index p_cpu_usage_report_cpu_usage_parent_vizql_session_idx;
drop index p_serverlogs_p_id_idx;
drop index p_serverlogs_parent_vizql_session_idx;
drop index p_serverlogs_bootstrap_rpt_parent_vizql_session_idx;
commit;

EOF

echo "End drop indexes $(date)" >> $LOGFILE

echo "Start vacuum (vacuum analyze in the case of p_serverlogs_bootstrap_rpt) tables by new partitions $(date)" >> $LOGFILE

psql -tc "select
                                case when p.tablename = 'p_serverlogs_bootstrap_rpt' then 'vacuum analyze ' else 'vacuum ' end || p.schemaname || '.\"' || p.partitiontablename || '\";'
                        from
                                pg_partitions p
                                left outer join pg_stat_operations o on (o.schemaname = p.schemaname and
                                                                                                                 o.objname = p.partitiontablename and
                                                                                                                 o.actionname = 'VACUUM'
                                                                                                                 )
                        where
								p.partitionschemaname = '$SCHEMA' and
                                p.tablename in ('p_serverlogs',
                                                                'p_cpu_usage',
                                                                'p_cpu_usage_report',
																'p_serverlogs_bootstrap_rpt'
                                                                ) and
                                p.parentpartitiontablename is null and
                                o.statime is null and
                                to_date(p.partitionname, 'yyyymmdd') < now()::date
                " $DBNAME | psql -a $DBNAME >> $LOGFILE 2>&1


echo "Start vacuum newly partitioned tables by new partitions $(date)" >> $LOGFILE

psql -tc "
select 
	vac_command
from (
	select
	        'vacuum ' || p.schemaname || '.\"' || p.partitiontablename || '\";' vac_command,
			row_number() over (partition by p.tablename order by partitionname desc) rn
	from
	        pg_partitions p
	        left outer join pg_stat_operations o on (o.schemaname = p.schemaname and
                                                     o.objname = p.partitiontablename and
                                                     o.actionname = 'VACUUM'
                                                     )
	where
			p.partitionschemaname = '$SCHEMA' and
	        p.tablename in (
							'p_interactor_session',
							'p_cpu_usage_agg_report',
							'p_process_class_agg_report',
							'p_cpu_usage_bootstrap_rpt') and
	        p.parentpartitiontablename is null) parts
where 
	parts.rn = 1
                " $DBNAME | psql -a $DBNAME >> $LOGFILE 2>&1

echo "End vacuum newly partitioned tables by new partitions $(date)" >> $LOGFILE				
echo "End vacuum (vacuum analyze in the case of p_serverlogs_bootstrap_rpt) tables by new partitions $(date)" >> $LOGFILE


echo "Start analyze tables by new partitions $(date)" >> $LOGFILE

psql -tc "select
                                'analyze ' || p.schemaname || '.\"' || p.partitiontablename || '\";'
                from
                        pg_partitions p
                        left outer join pg_stat_operations o on (o.schemaname = p.schemaname and
                                                                                                         o.objname = p.partitiontablename and
                                                                                                         o.actionname = 'ANALYZE'
                                                                                                         )
                where
						p.partitionschemaname = '$SCHEMA' and
                        p.tablename in ('p_serverlogs',
                                                        'p_cpu_usage',
                                                        'p_cpu_usage_report') and
                        p.parentpartitiontablename is not null and
                        o.statime is null and
                        to_date(p.parentpartitionname, 'yyyymmdd') < now()::date
                " $DBNAME | psql -a $DBNAME >> $LOGFILE 2>&1

echo "Start analyze newly partitioned tables by new partitions $(date)" >> $LOGFILE

psql -tc "
select 
	ana_command
from (
	select
	        'analyze ' || p.schemaname || '.\"' || p.partitiontablename || '\";' ana_command,
			row_number() over (partition by p.tablename order by partitionname desc) rn
	from
	        pg_partitions p
	        left outer join pg_stat_operations o on (o.schemaname = p.schemaname and
                                                     o.objname = p.partitiontablename and
                                                     o.actionname = 'ANALYZE'
                                                     )
	where
			p.partitionschemaname = '$SCHEMA' and
	        p.tablename in (
							'p_interactor_session',
							'p_cpu_usage_agg_report',
							'p_process_class_agg_report',
							'p_cpu_usage_bootstrap_rpt') and
	        p.parentpartitiontablename is null) parts
where 
	parts.rn = 1
                " $DBNAME | psql -a $DBNAME >> $LOGFILE 2>&1

echo "End analyze newly partitioned tables by new partitions $(date)" >> $LOGFILE
				
echo "End analyze tables by new partitions $(date)" >> $LOGFILE

echo "Start create indexes $(date)" >> $LOGFILE

psql $DBNAME >> $LOGFILE 2>&1 <<EOF
\set ON_ERROR_STOP on
set search_path = $SCHEMA;
set role palette_palette_updater;
begin;
CREATE INDEX p_cpu_usage_bootstrap_rpt_parent_vizql_session_idx ON p_cpu_usage_bootstrap_rpt USING btree (cpu_usage_parent_vizql_session);
CREATE INDEX p_cpu_usage_report_cpu_usage_parent_vizql_session_idx ON p_cpu_usage_report USING btree (cpu_usage_parent_vizql_session);
CREATE INDEX p_serverlogs_p_id_idx ON p_serverlogs USING btree (p_id);
CREATE INDEX p_serverlogs_parent_vizql_session_idx ON p_serverlogs USING btree (parent_vizql_session);
CREATE INDEX p_serverlogs_bootstrap_rpt_parent_vizql_session_idx ON p_serverlogs_bootstrap_rpt USING btree (parent_vizql_session);
commit;
EOF

echo "End create indexes $(date)" >> $LOGFILE

echo "Start set connection limit for readonly to -1 $(date)" >> $LOGFILE
psql $DBNAME -c "alter role readonly with CONNECTION LIMIT -1" >> $LOGFILE 2>&1
echo "End set connection limit for readonly to -1 $(date)" >> $LOGFILE


echo "Start handle missing grants on tables, $(date)" >> $LOGFILE

psql -tc "select
			case when r = 1 then owner_to_updater
				 when r = 2 then grant_to_looker
			end as cmd
		from 
			(
			select
				'alter table ' || t.schemaname || '.' || t.tablename || ' owner to palette_palette_updater;' as owner_to_updater,
				'grant select on ' || t.schemaname || '.' || t.tablename || ' to palette_palette_looker;' as grant_to_looker
			from pg_tables et
				inner join  pg_tables t on (t.schemaname = et.schemaname and
											case when substr(t.tablename, 1, 2) = 'h_' then substr(t.tablename, 3)
												 else t.tablename
											end = substr(et.tablename, 5)                                
											)
				left outer join information_schema.role_table_grants tg on (tg.table_schema = t.schemaname and
																			tg.table_name = t.tablename and
																			tg.privilege_type = 'SELECT' and
																			tg.grantee = 'palette_palette_looker')
			where 
				et.schemaname = '$SCHEMA' and
				et.tablename like 'ext#_%' escape '#' and
				et.tablename <> 'ext_error_table' and
				tg.grantee is null
			) p,
			(select generate_series(1,2) as r) gs
         " $DBNAME | psql -a $DBNAME >> $LOGFILE 2>&1
								
echo "End handle missing grants on tables, $(date)" >> $LOGFILE


echo "End maintenance $(date)" >> $LOGFILE
