FROM node:20

WORKDIR /usr/src/app

COPY ../package*.json ./
RUN npm install

COPY ../ .

RUN npm install

# For development (hot reload with nodemon)
RUN npm install -g ts-node nodemon

EXPOSE 3000

CMD ["npm", "run", "dev"]
