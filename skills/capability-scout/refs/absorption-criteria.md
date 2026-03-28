# Absorption Criteria

Judge candidates on the following axes:

1. signal quality
   - real architecture or code, not just branding
2. fit
   - aligns with harness artifact-first and repo-local constraints
3. modularity
   - the useful part can be separated from the whole
4. maintenance signal
   - recent activity, readable structure, sensible interfaces
5. local operating cost
   - dependencies, API keys, runtime complexity, and review surface

## Reuse modes

1. `adopt`
   - use nearly as-is
2. `wrap`
   - keep external runtime behind a local skill contract
3. `port`
   - reimplement a bounded slice in local scripts
4. `mimic`
   - copy the pattern, not the code
5. `reject`
   - record why it should not enter the harness
