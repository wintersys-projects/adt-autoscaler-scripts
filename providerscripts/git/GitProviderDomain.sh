if ( [ "${INFRASTRUCTURE_REPOSITORY_PROVIDER}" = "github" ] )
then
    /bin/echo "github.com"
fi
if ( [ "${INFRASTRUCTURE_REPOSITORY_PROVIDER}" = "bitbucket" ] )
then
    /bin/echo "bitbucket.org"
fi
if ( [ "${INFRASTRUCTURE_REPOSITORY_PROVIDER}" = "gitlab" ] )
then
    /bin/echo "gitlab.com"
fi