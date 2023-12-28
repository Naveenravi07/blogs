zola build
rsync -i "~/servers/personal_mumbai.pem" -R --delete /var/www/blogs/* admin@3.109.70.6:/var/www/blogs
git add .
git commit -m "Site rebuild"
git push
