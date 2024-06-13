# reproduce-gitea-issue
A little self-contained demo of an issue

To reproduce the issue, just run `reproduceGiteaBug.sh`. The script spins up a fresh instance of Gitea using Docker Compose. 
Using another container it creates a repository on this instance and creates two releases within this repository. 
One release is created as a draft, the other is created as final release. Both releases have the same file added as an attachment. 
Then the files are downloaded using curl, which results in the file content being displayed when things work as expected (up to Gitea version 1.21.11), otherwise it says "Not found" (as of Gitea version 1.22.0). 

