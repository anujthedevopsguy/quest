FROM node:10-alpine

USER node

RUN mkdir -p /home/node/app && chown -R node:node /home/node

# Set working directory
WORKDIR /home/node/app

RUN npm install && npm install express

# Copy  the application
COPY --chown=node:node . .

# Expose port and define entry point
EXPOSE 3000
ENTRYPOINT ["node", "src/000.js"]
