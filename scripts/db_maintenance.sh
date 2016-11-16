#!/bin/bash -l

DBNAME="palette"
SCHEMA="palette"
RETENTION_IN_DAYS=15
RETENTION_IN_MONTHS=2

analyze_partitions() {
    TABLES=$1
    HAS_SUBPART=$2       
    
    if [ ${HAS_SUBPART} -eq "1" ]; then
    
        DATE_COL_NAME="parentpartitionname"
    else
        DATE_COL_NAME="partitionname"
    fi
    
    psql -tc "select
                        'analyze ' || p.schemaname || '.\"' || p.partitiontablename || '\";'
                from
                        pg_partitions p
                        left outer join pg_stat_operations o on (o.schemaname = p.schemaname and
                                                                 o.objname = p.partitiontablename and
                                                                 o.actionname = 'ANALYZE'
                                                                 )
                where
						p.partitionschemaname = '${SCHEMA}' and
                        p.tablename in (${TABLES}) and
                        p.partitionlevel = ${HAS_SUBPART} and
                        o.statime is null and
                        to_date(p.${DATE_COL_NAME}, 'yyyymmdd') < now()::date
                " $DBNAME | psql -a $DBNAME 2>&1
    
}

delete_old_data() {
    TABLE=$1
    ORDER_COLUMN=$2
            
    psql $DBNAME -c "delete from ${SCHEMA}.${TABLE}
                    using
                        (select p_id
                        from
                            (select
                                p_id,
                                dense_rank() over (order by ${ORDER_COLUMN}::date desc) rn
                            from
                                ${SCHEMA}.${TABLE}) b
                         where
                            rn > ${RETENTION_IN_DAYS}
                        ) s
                    where
                        ${TABLE}.p_id = s.p_id"  2>&1
}


drop_old_partitions () {
  TABLES=$1
  RETENTION_PERIOD=$2

  psql -tc "select
                          drop_stmt
                  from
                          (
                          select
                                  'alter table ' || schemaname || '.' || tablename || ' drop partition \"' || partitionname || '\";' drop_stmt,
                                  row_number() over (partition by tablename order by partitionname desc) as rn
                          from pg_partitions t
                          where
                                  schemaname = '${SCHEMA}' and
                                  tablename in (${TABLES}) and
                                  partitiontype = 'range' and
                                  partitionname not in ('10010101', '100101')
                          ) a
                  where
                          rn > ${RETENTION_PERIOD}
                  order by 1
          " $DBNAME | psql -a $DBNAME 2>&1
}

log () {
    echo "$1 $(date)"
}

log "Start maintenance"

log "Start set connection limit for readonly to 0"
psql $DBNAME -c "alter role readonly with CONNECTION LIMIT 0" 2>&1
log "End set connection limit for readonly to 0"

log "Start terminate readonly connections"

psql -tc "select 'select pg_terminate_backend(' || procpid || ');'
from
        pg_stat_activity
where
        datname = '$SCHEMA' and
        usename = 'readonly'" $DBNAME | psql -a $DBNAME 2>&1

log "End terminate readonly connections"

log "Start deleting streaming tables"

delete_old_data "background_jobs" "created_at"
delete_old_data "http_requests" "created_at"
delete_old_data "countersamples" "timestamp"

log "End deleting streaming tables"

log "Start vacuum analyze history tables"

psql -tc "select 'vacuum analyze ' || schemaname || '.' || tablename || ';'
            from pg_tables
            where schemaname = '$SCHEMA'
                and tablename like 'h#_%' escape '#'
          " $DBNAME | psql -a $DBNAME 2>&1

log "End vacuum analyze history tables"

log "Start vacuum analyze p_http_requests and p_background_jobs"

psql $DBNAME 2>&1 <<EOF
\set ON_ERROR_STOP on
set search_path = $SCHEMA;
vacuum analyze $SCHEMA.p_http_requests;
vacuum $SCHEMA.p_background_jobs;
EOF

log "End vacuum analyze p_http_requests and p_background_jobs"

log "Start drop old partitions by day"

drop_old_partitions "'plainlogs', 'threadinfo', 'serverlogs', 'p_threadinfo', 'p_threadinfo_delta', 'p_serverlogs', 'p_cpu_usage', 'p_cpu_usage_report', 'p_serverlogs_bootstrap_rpt'" ${RETENTION_IN_DAYS}

log "End drop old partitions by day"

log "Start drop old partitions by month"

drop_old_partitions "'p_cpu_usage_bootstrap_rpt', 'p_process_class_agg_report'" ${RETENTION_IN_MONTHS}

log "End drop old partitions by month"

log "Start analyze tables by new partitions"

analyze_partitions "'p_serverlogs', 'p_cpu_usage', 'p_cpu_usage_report'" "1"
                
log "End analyze tables by new partitions"

log "Start analyze tables by last partitions"

psql -tc "
select
	ana_command
from (
	select
	        'analyze ' || p.schemaname || '.\"' || p.partitiontablename || '\";' ana_command,
			row_number() over (partition by p.tablename order by partitionname desc) rn
	from
	        pg_partitions p
	where
			p.partitionschemaname = '$SCHEMA' and
	        p.tablename in ('p_interactor_session') and
	        p.parentpartitiontablename is null) parts
where
	parts.rn = 1
                " $DBNAME | psql -a $DBNAME 2>&1

log "End analyze tables by last partitions"

log "Start set connection limit for readonly to -1"
psql $DBNAME -c "alter role readonly with CONNECTION LIMIT -1" 2>&1
log "End set connection limit for readonly to -1"


log "Start handle missing grants on tables,"

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
         " $DBNAME | psql -a $DBNAME 2>&1

log "End handle missing grants on tables"

# On Sundays
if [ $(date +%u) -eq 7 ]; then

    log "Start weekly analyze"

    log "Start vacuum analyze pg_catalog tables"

    psql -tc "select 'VACUUM ANALYZE ' || b.nspname || '.' || relname || ';'
    from
            pg_class a,
            pg_namespace b
    where
            a.relnamespace = b.oid and
            b.nspname in ('pg_catalog') and
            a.relkind='r'" $DBNAME | psql -a $DBNAME 2>&1

    log "End vacuum analyze pg_catalog tables"
    
    
    
    psql $DBNAME 2>&1 <<EOF
    \set ON_ERROR_STOP on
    set search_path = $SCHEMA;
    
    analyze p_process_classification;
    analyze serverlogs;
    analyze threadinfo;
    analyze plainlogs;
    analyze p_threadinfo;
    analyze p_threadinfo_delta;
    analyze rootpartition plainlogs;
    analyze rootpartition serverlogs;
    analyze rootpartition threadinfo;
    analyze rootpartition p_serverlogs;    
    analyze rootpartition p_threadinfo;
    analyze rootpartition p_threadinfo_delta;
    analyze rootpartition p_cpu_usage;
    analyze rootpartition p_cpu_usage_report;
    analyze rootpartition p_interactor_session;    

EOF

    log "End weekly analyze"
fi


log "End maintenance"
