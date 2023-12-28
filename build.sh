zola build
rsync -i "/home/shastri/servers/personal_mumbai.pem" -arP --delete /var/www/blogs/* admin@3.109.70.6:/var/www/blogs
git add .
git commit -m "Site rebuild"
git push
