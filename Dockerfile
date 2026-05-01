FROM node:20-alpine AS client-builder

WORKDIR /app/client

COPY client/package*.json ./
RUN npm ci

COPY client/ ./
RUN npm run build

FROM node:20-alpine AS server-builder

WORKDIR /app/server

COPY server/package*.json ./
RUN npm ci

COPY server/ ./
RUN npm run build

FROM node:20-alpine AS runtime

WORKDIR /app/server

# The API uses `git clone` for repository analysis.
RUN apk add --no-cache git

ENV NODE_ENV=production
ENV PORT=3000

# Install only runtime dependencies for the server.
COPY server/package*.json ./
RUN npm ci --omit=dev

# Copy compiled backend and client static bundle.
COPY --from=server-builder /app/server/dist ./dist
COPY --from=client-builder /app/client/dist /app/client/dist

EXPOSE 3000

CMD ["node", "dist/server.js"]
