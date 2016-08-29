  # Upload the RPM to the RPM repository
  # by exportin it to SSHPASS, sshpass wont log the command line and the password
echo "DEPLOY_USER=$DEPLOY_USER"
echo "DEPLOY_HOST=$DEPLOY_HOST"

ls -latr ~/.ssh/known_hosts

export SSHPASS=$DEPLOY_PASS
sshpass -e scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r rpm-build/_build/* $DEPLOY_USER@$DEPLOY_HOST:$DEPLOY_PATH

# Update the RPM repository
export DEPLOY_CMD="createrepo ${DEPLOY_PATH}/"
sshpass -e ssh  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $DEPLOY_USER@$DEPLOY_HOST $DEPLOY_CMD


