// From Manual to Macro
// Apoorva Bhandari et al.
// JHC 2026
// Fiji/ImageJ macro for collagen fibril analysis

// Fibre diameters (Eq, Major, Minor) + QA + Quadrant + simple visual check
// Fiji/ImageJ 1.54p — IJ1 macro language

function toMicrons_len(v,u){
  u=toLowerCase(u);
  if (u=="µm"||u=="μm"||u=="um"||u=="micrometer"||u=="micrometers"||u=="micron"||u=="microns") return v;
  if (u=="mm"||u=="millimeter"||u=="millimeters") return v*1000.0;
  if (u=="cm"||u=="centimeter"||u=="centimeters") return v*10000.0;
  if (u=="m" ||u=="meter"||u=="meters") return v*1.0e6;
  if (u=="inch"||u=="inches"||u=="in") return v*25400.0;
  if (u=="pixel"||u=="pixels") exit("No scale set. Use Analyze → Set Scale.");
  return v;
}
function toMicrons_area(v,u){
  u=toLowerCase(u);
  if (u=="µm"||u=="μm"||u=="um"||u=="micrometer"||u=="micrometers"||u=="micron"||u=="microns") return v;
  if (u=="mm"||u=="millimeter"||u=="millimeters") return v*1000.0*1000.0;
  if (u=="cm"||u=="centimeter"||u=="centimeters") return v*10000.0*10000.0;
  if (u=="m" ||u=="meter"||u=="meters") return v*1.0e6*1.0e6;
  if (u=="inch"||u=="inches"||u=="in") return v*25400.0*25400.0;
  if (u=="pixel"||u=="pixels") exit("No scale set. Use Analyze → Set Scale.");
  return v;
}

macro "Wand -> Fibre Diameters + QA + Quadrant [q]" {
  if (selectionType()==-1) exit("No active selection. Wand-click the fibre (marching ants).");
  st=selectionType(); if (st<0 || st>4) exit("Selection is not an AREA. Use the Wand (not a line/point).");

  // Measure: Area, ellipse, centroid
  run("Set Measurements...", "area fit centroid redirect=None decimal=6");
  run("Measure");
  r = nResults-1;

  // Units & EqDiam (area-based)
  getPixelSize(unit, pw, ph, pd);                 // pw = length per pixel in 'unit'
  area_raw=getResult("Area", r); if (area_raw<=0) exit("Area measured as 0. Adjust Wand tolerance.");
  area_um2 = toMicrons_area(area_raw, unit);
  eq_um    = 2.0*sqrt(area_um2/PI);

  // Ellipse axes (already in image units -> convert safely)
  maj_um = toMicrons_len(getResult("Major", r), unit);
  min_um = toMicrons_len(getResult("Minor", r), unit);
  ang_deg = getResult("Angle", r);

  // QA columns
  axis_ratio   = maj_um / min_um;
  eq_axes_um   = sqrt(maj_um * min_um);
  eqdiff_pct   = 100.0 * abs(eq_um - eq_axes_um) / eq_um;

  // Quadrant (use centroid, convert from µm -> px to compare with image centre in px)
  um_per_px = toMicrons_len(pw, unit);
  cx_um = getResult("X", r);  cy_um = getResult("Y", r);
  cx = cx_um/um_per_px;       cy = cy_um/um_per_px;
  iw=getWidth(); ih=getHeight();
  if      (cx<iw/2 && cy<ih/2) quad="Q1";
  else if (cx>=iw/2 && cy<ih/2) quad="Q2";
  else if (cx<iw/2 && cy>=ih/2) quad="Q3";
  else                          quad="Q4";

  // Write outputs (ASCII-safe headers)
  setResult("EqDiam_um",      r, d2s(eq_um,6));
  setResult("EqDiam_axes_um", r, d2s(eq_axes_um,6));
  setResult("EqDiff_%",       r, d2s(eqdiff_pct,3));
  setResult("AxisRatio",      r, d2s(axis_ratio,3));
  setResult("Quadrant",       r, quad);
  updateResults();

  // Visual check overlays (no labels): outline + axes
  run("Overlay Options...", "stroke=magenta width=2 fill=none");
  run("Add Selection...");

  // Draw Minor (green) and Major (blue) through centroid
  maj_px = maj_um/um_per_px;  min_px = min_um/um_per_px;
  th = ang_deg*PI/180.0; th_min = th + PI/2.0;

  run("Overlay Options...", "stroke=green width=2 fill=none");
  makeLine(cx-(min_px/2.0)*cos(th_min), cy-(min_px/2.0)*sin(th_min),
           cx+(min_px/2.0)*cos(th_min), cy+(min_px/2.0)*sin(th_min)); run("Add Selection...");

  run("Overlay Options...", "stroke=blue width=2 fill=none");
  makeLine(cx-(maj_px/2.0)*cos(th),     cy-(maj_px/2.0)*sin(th),
           cx+(maj_px/2.0)*cos(th),     cy+(maj_px/2.0)*sin(th));     run("Add Selection...");
}
