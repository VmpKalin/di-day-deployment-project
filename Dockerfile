# Stage 1: build the Vite bundle
FROM node:22-alpine AS build
WORKDIR /app

# Dependency layer first — source changes must not invalidate npm ci
COPY app/package.json app/package-lock.json ./
RUN npm ci
COPY app/ ./

# ARGs are stage-scoped: declare them here, in the stage that runs the build.
ARG VITE_APP_VERSION
ARG VITE_GIT_SHA
ARG VITE_GIT_BRANCH
ARG VITE_BUILD_TIME

# Promote ARG -> ENV: Vite reads import.meta.env from the process environment
# of `npm run build`, and a bare ARG is not reliably visible there. Without
# this the page silently falls back to dev-local.
ENV VITE_APP_VERSION=$VITE_APP_VERSION
ENV VITE_GIT_SHA=$VITE_GIT_SHA
ENV VITE_GIT_BRANCH=$VITE_GIT_BRANCH
ENV VITE_BUILD_TIME=$VITE_BUILD_TIME

RUN npm run build

# Stage 2: serve with unprivileged nginx (non-root, port 8080)
FROM nginxinc/nginx-unprivileged:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:8080/healthz || exit 1
