# SimpleOban

This will reproduce the growing of the ETS table for our Repo `SimpleOban.Repo`

This behaviour happens on clustered node with global limit.

You can start the 2 node with 
- `./node1.sh`
- `./node2.sh`

You then need to insert the crons jobs:
- `SimpleOban.BaseWorker.insert_cron_jobs`

I am listing all the stored keys in the homepage: [homepage](http://localhost:4000)

You can always check on the dashboard:  [Dashboard](http://localhost:4000/dev/dashboard/ets?limit=50&search=SimpleOban.Repo&sort_by=memory&sort_dir=desc)


