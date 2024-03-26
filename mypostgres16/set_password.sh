echo
echo Set password for postgres user
echo
psql <<EOF
\password
\q
EOF
echo
echo Done.
echo