FROM node:10-alpine

# Set working directory
WORKDIR /home/node/app

# Copy package.json and install dependencies
COPY --chown=node:node package.json ./
USER node
RUN npm install

# Copy the rest of the application
COPY --chown=node:node . .

# Expose port and define entry point
EXPOSE 8080
CMD ["node", "bin/000.js"]
