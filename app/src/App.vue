<script setup>
const val = (v, fallback) => (v && v.length ? v : fallback)

const version = val(import.meta.env.VITE_APP_VERSION, '0.0.0-dev')
const sha = val(import.meta.env.VITE_GIT_SHA, 'dev-local')
const branch = val(import.meta.env.VITE_GIT_BRANCH, 'dev-local')
const buildTime = val(import.meta.env.VITE_BUILD_TIME, 'not-injected')
</script>

<template>
  <main class="page">
    <h1>di-test-project</h1>
    <div class="block">
      <div class="label">commit</div>
      <div class="sha">{{ sha }}</div>
      <div class="label">branch</div>
      <div class="branch">{{ branch }}</div>
      <div class="meta">
        <span>version {{ version }}</span>
        <span>built {{ buildTime }}</span>
      </div>
    </div>
  </main>
</template>

<style scoped>
.page {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 2rem;
}
h1 {
  font-size: 1.5rem;
  font-weight: 400;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  opacity: 0.7;
}
.block {
  text-align: center;
  border: 2px solid currentColor;
  border-radius: 12px;
  padding: 2.5rem 4rem;
}
.label {
  font-size: 1rem;
  text-transform: uppercase;
  letter-spacing: 0.2em;
  opacity: 0.6;
  margin-top: 1.5rem;
}
.label:first-child {
  margin-top: 0;
}
.sha {
  font-family: ui-monospace, 'Cascadia Code', Consolas, monospace;
  font-size: 48px;
  font-weight: 700;
}
.branch {
  font-size: 40px;
  font-weight: 700;
}
.meta {
  margin-top: 2rem;
  display: flex;
  gap: 2rem;
  justify-content: center;
  font-family: ui-monospace, 'Cascadia Code', Consolas, monospace;
  font-size: 1rem;
  opacity: 0.8;
}
</style>
