FROM node:24-slim
WORKDIR /app
RUN npm install --prefix /opt/luau --no-save --ignore-scripts --no-audit --no-fund luau-web@1.4.0
COPY . .
CMD ["sh", "-c", "node tests/run-luau.mjs /opt/luau/node_modules/luau-web/src/index.js && node --test tests/telemetry.test.mjs tests/studio-sync.test.mjs"]
