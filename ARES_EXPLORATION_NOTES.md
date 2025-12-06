# Ares Export Exploration - Lessons Learned

## Summary
Attempted to get Achilles exportToAres() working with PostgreSQL.

## Key Findings

### Issue
- `Achilles::exportToAres()` has deep PostgreSQL compatibility issues
- Root cause: Designed for Oracle/SQL Server, assumes uppercase column names
- PostgreSQL stores identifiers as lowercase (SQL standard)

### What We Tried
1. ✅ Manual export script - **WORKED** (290 analyses exported)
2. ❌ Patching exportToAres (3 lines) - Incomplete
3. ❌ Comprehensive patch (44 querySql calls) - Still failed on data joins
4. ❌ Safe mode export (skip density) - Failed on observation period
5. ❌ Enhanced manual for AresIndexer - Indexer format issues

### What Actually Works
- ✅ **Atlas** - View Achilles results directly, no export needed
- ✅ **Manual export** - Creates core files, partial Ares compatibility

### Recommendation
**Use Atlas for visualization.** It reads directly from the database, no export/indexing needed.

## Files Created (saved in feature/ares-export-exploration branch)
- `hades/manual-export-achilles-fixed.R` - Working manual export
- `hades/manual-export-achilles-enhanced.R` - Enhanced for AresIndexer
- `hades/run-dqd-fixed.R` - PostgreSQL-compatible DQD
- `hades/exportToAres-patched.R` - Attempted comprehensive patch (incomplete)

## Conclusion
Official OHDSI tools (exportToAres, AresIndexer) need significant work for full PostgreSQL support. For now, Atlas 
provides all needed functionality without the complexity.