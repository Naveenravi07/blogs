zola build
rsync -e "ssh -i "~/servers/personal_mumbai.pem""  -av public/*  root@3.109.70.6:/var/www/blogs
git add .
git commit -m "Site rebuild"
git push
