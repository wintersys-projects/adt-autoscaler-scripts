set -x
infrastructure_repository_provider="${1}"

if ( [ "${infrastructure_repository_provider}" = "github" ] )
then
    /bin/echo "github.com"
fi

if ( [ "${infrastructure_repository_provider}" = "bitbucket" ] )
then
    /bin/echo "bitbucket.org"
fi

if ( [ "${infrastructure_repository_provider}" = "gitlab" ] )
then
    /bin/echo "gitlab.com"
fi
