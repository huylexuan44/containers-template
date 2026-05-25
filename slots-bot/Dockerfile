# Build from repo root: docker compose -f containers-template/docker-compose.slots.yml build
FROM node:20-bookworm-slim AS build

WORKDIR /app
COPY utility-mezon-bot/tools/slots-cli/package.json utility-mezon-bot/tools/slots-cli/package-lock.json ./
RUN npm ci

COPY utility-mezon-bot/tools/slots-cli/tsconfig.json ./
COPY utility-mezon-bot/tools/slots-cli/src ./src
RUN npm run build

FROM node:20-bookworm-slim

WORKDIR /app
COPY utility-mezon-bot/tools/slots-cli/package.json utility-mezon-bot/tools/slots-cli/package-lock.json ./
RUN npm ci --omit=dev

COPY --from=build /app/dist ./dist
COPY containers-template/slots-bot/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV NODE_ENV=production

ENTRYPOINT ["/entrypoint.sh"]
