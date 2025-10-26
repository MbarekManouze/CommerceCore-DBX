for f in ./migrations/functions/*.sql; do
    echo "Running $f ..."
    docker exec -i app_db psql -U dbuser -d myapp < "$f"
done