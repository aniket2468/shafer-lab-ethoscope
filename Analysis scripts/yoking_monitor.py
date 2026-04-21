#!/usr/bin/env python3
"""
Yoking Verification Script for Ethoscope Data
Checks if yoking worked correctly across all ethoscope databases
"""

import sqlite3
import pandas as pd
import numpy as np
from pathlib import Path
from datetime import datetime
import json

# Configuration
DATA_DIR = Path("/Users/aniketsharma/Documents/Research Assistant/Ethoscope/ethoscope_data")

# Expected yoking configuration
YOKE_CONFIG = {
    "12": "1",   # ROI 12 yoked to ROI 1
    "14": "3",   # ROI 14 yoked to ROI 3
    "16": "5",   # ROI 16 yoked to ROI 5
    "18": "7",   # ROI 18 yoked to ROI 7
    "20": "9"    # ROI 20 yoked to ROI 9
}


def get_interaction_data(db_path, roi_id):
    """Get has_interacted data from a specific ROI table"""
    conn = sqlite3.connect(db_path)
    
    try:
        # Check if has_interacted column exists
        query = f"PRAGMA table_info(ROI_{roi_id})"
        columns = pd.read_sql_query(query, conn)
        
        if 'has_interacted' not in columns['name'].values:
            conn.close()
            return None
        
        # Get interaction data
        df = pd.read_sql_query(
            f"SELECT t, has_interacted FROM ROI_{roi_id} WHERE has_interacted > 0",
            conn
        )
        conn.close()
        return df
    except Exception as e:
        conn.close()
        return None


def verify_yoking(db_path):
    """Verify that yoking worked correctly for a single database"""
    results = {
        "db_name": db_path.name,
        "ethoscope": None,
        "metadata_check": None,
        "yoke_pairs": {}
    }
    
    # Extract ethoscope name
    name_parts = db_path.stem.split('_')
    for i, part in enumerate(name_parts):
        if part == 'ETHOSCOPE' and i + 1 < len(name_parts):
            results["ethoscope"] = f"ETHOSCOPE_{name_parts[i+1]}"
            break
    
    # Check yoking for each pair
    for yoked_roi, master_roi in YOKE_CONFIG.items():
        master_data = get_interaction_data(db_path, master_roi)
        yoked_data = get_interaction_data(db_path, yoked_roi)
        
        pair_key = f"ROI {yoked_roi} ← ROI {master_roi}"
        pair_result = {
            "master_interactions": 0,
            "yoked_interactions": 0,
            "matched_interactions": 0,
            "match_rate": 0.0,
            "status": "UNKNOWN"
        }
        
        if master_data is None or len(master_data) == 0:
            pair_result["status"] = "NO_MASTER_DATA"
        elif yoked_data is None or len(yoked_data) == 0:
            pair_result["status"] = "NO_YOKED_DATA"
            pair_result["master_interactions"] = len(master_data)
        else:
            pair_result["master_interactions"] = len(master_data)
            pair_result["yoked_interactions"] = len(yoked_data)
            
            # Check time matching (within 100ms tolerance)
            master_times = set(master_data['t'].values)
            yoked_times = set(yoked_data['t'].values)
            
            # Count matching timestamps (allow small tolerance)
            matched = 0
            tolerance = 100  # 100ms tolerance
            for mt in master_times:
                for yt in yoked_times:
                    if abs(mt - yt) <= tolerance:
                        matched += 1
                        break
            
            pair_result["matched_interactions"] = matched
            if pair_result["master_interactions"] > 0:
                pair_result["match_rate"] = (matched / pair_result["master_interactions"]) * 100
            
            # Determine status
            if pair_result["match_rate"] > 90:
                pair_result["status"] = "✓ YOKING WORKED"
            elif pair_result["match_rate"] > 50:
                pair_result["status"] = "⚠ PARTIAL YOKING"
            elif pair_result["matched_interactions"] > 0:
                pair_result["status"] = "⚠ POOR YOKING"
            else:
                pair_result["status"] = "✗ YOKING FAILED"
        
        results["yoke_pairs"][pair_key] = pair_result
    
    return results


def print_results(all_results):
    """Print formatted results"""
    print("\n" + "="*80)
    print("YOKING VERIFICATION REPORT")
    print("="*80)
    print(f"Expected yoking config: {YOKE_CONFIG}")
    print("="*80)
    
    for result in all_results:
        print(f"\n{'─'*80}")
        print(f"📁 {result['ethoscope'] or 'UNKNOWN'}")
        print(f"   File: {result['db_name']}")
        
        # Yoking results
        print(f"\n   🔗 YOKING VERIFICATION:")
        
        total_master = 0
        total_matched = 0
        
        for pair_key, pair_result in result["yoke_pairs"].items():
            status = pair_result["status"]
            master = pair_result["master_interactions"]
            yoked = pair_result["yoked_interactions"]
            matched = pair_result["matched_interactions"]
            rate = pair_result["match_rate"]
            
            total_master += master
            total_matched += matched
            
            print(f"      {pair_key}:")
            print(f"         Master stim: {master}, Yoked stim: {yoked}, Matched: {matched} ({rate:.1f}%)")
            print(f"         {status}")
        
        # Overall assessment
        print(f"\n   📊 OVERALL:")
        if total_master == 0:
            print(f"      ❓ No stimulations recorded - can't verify yoking")
        else:
            overall_rate = (total_matched / total_master) * 100 if total_master > 0 else 0
            print(f"      Total master stimulations: {total_master}")
            print(f"      Total matched yoked stimulations: {total_matched}")
            print(f"      Overall match rate: {overall_rate:.1f}%")
            
            if overall_rate > 90:
                print(f"      ✓✓ YOKING WORKED CORRECTLY")
            elif overall_rate > 50:
                print(f"      ⚠ YOKING PARTIALLY WORKED")
            else:
                print(f"      ✗ YOKING DID NOT WORK AS EXPECTED")


def main():
    print("="*80)
    print("ETHOSCOPE YOKING VERIFICATION TOOL")
    print("="*80)
    
    # Find all database files recursively in subdirectories of ethoscope_data
    db_files = sorted(list(DATA_DIR.glob("**/*.db")))
    print(f"\nSearching recursively in: {DATA_DIR}")
    print(f"Found {len(db_files)} database files")
    
    if len(db_files) == 0:
        print(f"ERROR: No database files found in {DATA_DIR} or its subdirectories!")
        return
    
    # Analyze each database
    all_results = []
    for db_path in db_files:
        rel_path = db_path.relative_to(DATA_DIR)
        print(f"\nAnalyzing: {rel_path}...")
        try:
            result = verify_yoking(db_path)
            all_results.append(result)
        except Exception as e:
            print(f"  ERROR: {e}")
    
    # Print results
    print_results(all_results)
    
    # Summary
    print("\n" + "="*80)
    print("QUICK SUMMARY")
    print("="*80)
    
    for result in all_results:
        ethoscope = result['ethoscope'] or 'UNKNOWN'
        meta_status = "-"
        
        # Calculate overall yoking status
        total_master = sum(p["master_interactions"] for p in result["yoke_pairs"].values())
        total_matched = sum(p["matched_interactions"] for p in result["yoke_pairs"].values())
        
        if total_master == 0:
            yoke_status = "❓ No data"
        elif total_matched / total_master > 0.9:
            yoke_status = "✓ Working"
        elif total_matched / total_master > 0.5:
            yoke_status = "⚠ Partial"
        else:
            yoke_status = "✗ Failed"
        
        print(f"  {ethoscope:20} | Yoking: {yoke_status}")
    
    print("="*80)


if __name__ == "__main__":
    main()