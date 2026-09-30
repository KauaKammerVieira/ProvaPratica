FROM node:24-alpine AS base

WORKDIR /app


FROM base AS frontend-deps

COPY frontend/package.json frontend/package-lock.json ./

RUN npm ci


# ==========================================
# FRONTEND - BUILD
# ==========================================
FROM frontend-deps AS frontend-build

COPY frontend/ .

RUN npm run build


FROM node:24-alpine AS frontend

WORKDIR /app

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=frontend-deps --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=frontend-deps --chown=appuser:appgroup /app/package.json ./package.json
COPY --from=frontend-deps --chown=appuser:appgroup /app/package-lock.json ./package-lock.json
COPY --from=frontend-build --chown=appuser:appgroup /app/dist ./dist

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

CMD ["npm", "run", "preview", "--", "--host", "0.0.0.0", "--port", "8080"]



FROM base AS backend-deps

COPY backend/package.json backend/package-lock.json ./

RUN npm ci --omit=dev


# ==========================================
# BACKEND
# ==========================================
FROM node:24-alpine AS backend

WORKDIR /app

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=backend-deps --chown=appuser:appgroup /app/node_modules ./node_modules

COPY backend/package.json ./

COPY backend/src ./src

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/frutas || exit 1

CMD ["node", "src/main.js"]
