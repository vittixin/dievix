unit DieVix.ReportService;

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  Phase 5 Reporting Service Layer (VittixReport Integration)
  
  Orchestrates professional vector printing, interactive preview, and headless
  PDF/XLSX export for:
    1. Die Tooling Job Bag Card (die_tooling_card.vrt)
    2. Die Master Register Catalog (die_register_catalog.vrt)
    3. Machine Fleet Cylinder Tooling Matrix (cylinder_fleet_matrix.vrt)
==============================================================================}

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  DieVix.Domain,
  DieVix.ConnectionManager,
  DieVix.CalculationEngine,
  Vittix.Report.Component,
  Vittix.Report.UserDataSet,
  Vittix.Report.Objects.Barcode;

type
  { Report Execution Action }
  TReportAction = (raPreview, raVectorPdf, raXlsx);

  { Reporting Application Service }
  TDieVixReportService = class
  private
    FConnection: TFDConnection;
    FReportsPath: string;
    function GetConnection: TFDConnection;
    function CreateQuery: TFDQuery;
    function ResolveTemplate(const AReportFileName: string): string;
    function GetEmbeddedTemplate(const AReportFileName: string): string;
    function ExecuteReport(
      const AReportFileName: string;
      const ADataSetName: string;
      const AQry: TFDQuery;
      const AAction: TReportAction;
      const AOutFilePath: string = '';
      AParameters: TStrings = nil
    ): Boolean;
    procedure BuildFlatbedCatalogQuery(
      const AQry: TFDQuery;
      const AFilter: TFlatbedDieSearchFilter;
      const AParams: TStrings
    );
  public
    constructor Create(AConnection: TFDConnection = nil; const AReportsPath: string = '');

    { Custom base directory where .vrt template files reside }
    property ReportsPath: string read FReportsPath write FReportsPath;

    { 1. Die Tooling Job Bag Card }
    procedure PreviewToolingCard(const ADieID: Integer);
    function ExportToolingCardPdf(const ADieID: Integer; const AOutPdfPath: string): Boolean;

    { 2. Die Master Register Catalog }
    procedure PreviewRegisterCatalog(const AFilter: TDieSearchFilter);
    function ExportRegisterCatalogPdf(const AFilter: TDieSearchFilter; const AOutPdfPath: string): Boolean;
    function ExportRegisterCatalogXlsx(const AFilter: TDieSearchFilter; const AOutXlsxPath: string): Boolean;

    { 3. Machine Fleet Cylinder Tooling Matrix }
    procedure PreviewFleetMatrix;
    function ExportFleetMatrixPdf(const AOutPdfPath: string): Boolean;
    function ExportFleetMatrixXlsx(const AOutXlsxPath: string): Boolean;

    { 4. Flatbed Die Tooling Job Bag Card }
    procedure PreviewFlatbedToolingCard(const AFlatbedDieID: Integer);
    function ExportFlatbedToolingCardPdf(const AFlatbedDieID: Integer; const AOutPdfPath: string): Boolean;

    { 5. Flatbed Die Master Register Catalog }
    procedure PreviewFlatbedRegisterCatalog(const AFilter: TFlatbedDieSearchFilter);
    function ExportFlatbedRegisterCatalogPdf(const AFilter: TFlatbedDieSearchFilter; const AOutPdfPath: string): Boolean;
    function ExportFlatbedRegisterCatalogXlsx(const AFilter: TFlatbedDieSearchFilter; const AOutXlsxPath: string): Boolean;
  end;

implementation

{ TDieVixReportService }

constructor TDieVixReportService.Create(AConnection: TFDConnection; const AReportsPath: string);
begin
  inherited Create;
  FConnection := AConnection;
  FReportsPath := AReportsPath;
end;

function TDieVixReportService.GetConnection: TFDConnection;
begin
  if Assigned(FConnection) then
    Result := FConnection
  else
    Result := TDieVixConnectionManager.Instance.GetConnection;
end;

function TDieVixReportService.CreateQuery: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := GetConnection;
end;

function TDieVixReportService.GetEmbeddedTemplate(const AReportFileName: string): string;
var
  BaseName: string;
begin
  BaseName := LowerCase(ExtractFileName(AReportFileName));
  if (BaseName = 'die_tooling_card.vrt') then
  begin
    Result :=
      '{"Version":2,"Title":"Die Tooling Job Bag Card","Author":"DieVix","PageSettings":{"PaperSize":0,"Orientation":0,"MarginLeft":30,"MarginTop":30,"MarginRight":30,"MarginBottom":30,"CustomWidth":793,"CustomHeight":1122},' +
      '"FieldNames":["ID","SERIAL_NO","CUSTOMER_CODE","CUSTOMER_NAME","CUSTOMER_REF","TEETH","PITCH_UM","REPEAT_MM","REPEAT_INCH","AROUND_SIZE_MM","ACROSS_SIZE_MM","AROUND_UPS","ACROSS_UPS","TOTAL_UPS","AROUND_GAP_MM","ACROSS_GAP_MM","CORNER_RADIUS_MM","SHAPE","CUT_TYPE","STATUS_CODE","STATUS_NAME","GAP_POLICY_STATUS","STORAGE_LOCATION","STORAGE_RACK","STORAGE_SHELF","STORAGE_BIN","MEDIA_CODE","MEDIA_NAME","FACE_MATERIAL","LINER_MATERIAL","ADHESIVE_TYPE","TOTAL_CALIPER_UM","DIE_MAKER","SUPPLIER_REF","TOTAL_RUN_METRES","OVERRIDE_REASON","NOTES","CREATED_BY","CREATED_AT"],' +
      '"DataSetNames":["DieData"],"Objects":[' +
      '{"Class":"TReportBand","Name":"BandTitle","Bounds":{"L":0,"T":0,"R":733,"B":90},"Visible":true,"BandType":0,"Height":90,"Children":[' +
      '{"Class":"TReportTextObject","Name":"lblAppTitle","Bounds":{"L":0,"T":4,"R":420,"B":28},"Visible":true,"Text":"DieVix - Rotary Die Tooling Job Bag Card","FontName":"Segoe UI","FontSize":14,"FontColor":1973790,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"lblSubtitle","Bounds":{"L":0,"T":28,"R":420,"B":44},"Visible":true,"Text":"Authoritative Shop-Floor Production Specification","FontName":"Segoe UI","FontSize":9,"FontColor":5395026,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"lblHeaderSerial","Bounds":{"L":0,"T":50,"R":420,"B":84},"Visible":true,"Text":"TOOLING SERIAL: [SERIAL_NO]","FontName":"Segoe UI","FontSize":16,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportBarcodeObject","Name":"barSerialCode","Bounds":{"L":480,"T":8,"R":730,"B":78},"Visible":true,"Value":"[SERIAL_NO]","DataField":"SERIAL_NO","Symbology":1,"ShowText":true,"BarColor":0,"BackgroundColor":16777215}' +
      ']},' +
      '{"Class":"TReportBand","Name":"BandMaster","Bounds":{"L":0,"T":0,"R":733,"B":580},"Visible":true,"BandType":2,"Height":580,"DataSetName":"DieData","Children":[' +
      '{"Class":"TReportShapeObject","Name":"boxCyl","Bounds":{"L":0,"T":4,"R":733,"B":90},"Visible":true,"ShapeType":0,"PenColor":13421772,"PenWidth":1,"BrushColor":16382457,"BrushStyle":0},' +
      '{"Class":"TReportTextObject","Name":"hCyl","Bounds":{"L":10,"T":8,"R":720,"B":24},"Visible":true,"Text":"1. CYLINDER & TOOLING REPEAT SPECIFICATIONS","FontName":"Segoe UI","FontSize":10,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"vCyl1","Bounds":{"L":10,"T":30,"R":360,"B":46},"Visible":true,"Text":"Cylinder Teeth: [TEETH] T","FontName":"Segoe UI","FontSize":9,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"vCyl2","Bounds":{"L":370,"T":30,"R":720,"B":46},"Visible":true,"Text":"Repeat Length: [REPEAT_MM] mm ([REPEAT_INCH] in)","FontName":"Segoe UI","FontSize":9,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"vCyl3","Bounds":{"L":10,"T":50,"R":360,"B":66},"Visible":true,"Text":"Gear Pitch: [PITCH_UM] um","FontName":"Segoe UI","FontSize":9,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"vCyl4","Bounds":{"L":370,"T":50,"R":720,"B":66},"Visible":true,"Text":"Tooling Status: [STATUS_NAME] ([STATUS_CODE])","FontName":"Segoe UI","FontSize":9,"Transparent":true},' +
      '{"Class":"TReportShapeObject","Name":"boxGeom","Bounds":{"L":0,"T":98,"R":733,"B":200},"Visible":true,"ShapeType":0,"PenColor":13421772,"PenWidth":1,"BrushColor":16777215,"BrushStyle":0},' +
      '{"Class":"TReportTextObject","Name":"hGeom","Bounds":{"L":10,"T":102,"R":720,"B":118},"Visible":true,"Text":"2. LABEL GEOMETRY & IMPOSITION","FontName":"Segoe UI","FontSize":10,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"vGeom1","Bounds":{"L":10,"T":124,"R":360,"B":140},"Visible":true,"Text":"Label Size (Around x Across): [AROUND_SIZE_MM] x [ACROSS_SIZE_MM] mm","FontName":"Segoe UI","FontSize":9,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"vGeom2","Bounds":{"L":370,"T":124,"R":720,"B":140},"Visible":true,"Text":"Imposition: [AROUND_UPS] Around x [ACROSS_UPS] Across ([TOTAL_UPS] Total Ups)","FontName":"Segoe UI","FontSize":9,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"vGeom3","Bounds":{"L":10,"T":144,"R":360,"B":160},"Visible":true,"Text":"Gaps: Around [AROUND_GAP_MM] mm | Across [ACROSS_GAP_MM] mm","FontName":"Segoe UI","FontSize":9,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"vGeom4","Bounds":{"L":370,"T":144,"R":720,"B":160},"Visible":true,"Text":"Corner Radius: [CORNER_RADIUS_MM] mm | Shape: [SHAPE]","FontName":"Segoe UI","FontSize":9,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"vGeom5","Bounds":{"L":10,"T":164,"R":720,"B":180},"Visible":true,"Text":"Gap Policy Validation: [GAP_POLICY_STATUS]","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportShapeObject","Name":"boxCust","Bounds":{"L":0,"T":208,"R":733,"B":295},"Visible":true,"ShapeType":0,"PenColor":13421772,"PenWidth":1,"BrushColor":16777215,"BrushStyle":0},' +
      '{"Class":"TReportTextObject","Name":"hCust","Bounds":{"L":10,"T":212,"R":720,"B":228},"Visible":true,"Text":"3. CUSTOMER & SUBSTRATE SPECIFICATION","FontName":"Segoe UI","FontSize":10,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"vCust1","Bounds":{"L":10,"T":232,"R":360,"B":248},"Visible":true,"Text":"Customer: [CUSTOMER_NAME] ([CUSTOMER_CODE])","FontName":"Segoe UI","FontSize":9,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"vCust2","Bounds":{"L":370,"T":232,"R":720,"B":248},"Visible":true,"Text":"Customer Part / Ref: [CUSTOMER_REF]","FontName":"Segoe UI","FontSize":9,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"vCust3","Bounds":{"L":10,"T":252,"R":360,"B":268},"Visible":true,"Text":"Target Media: [MEDIA_NAME] ([MEDIA_CODE])","FontName":"Segoe UI","FontSize":9,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"vCust4","Bounds":{"L":370,"T":252,"R":720,"B":268},"Visible":true,"Text":"Face: [FACE_MATERIAL] | Liner: [LINER_MATERIAL]","FontName":"Segoe UI","FontSize":9,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"vCust5","Bounds":{"L":10,"T":272,"R":720,"B":288},"Visible":true,"Text":"Adhesive: [ADHESIVE_TYPE] | Caliper: [TOTAL_CALIPER_UM] um","FontName":"Segoe UI","FontSize":9,"Transparent":true},' +
      '{"Class":"TReportShapeObject","Name":"boxLoc","Bounds":{"L":0,"T":303,"R":733,"B":375},"Visible":true,"ShapeType":0,"PenColor":13421772,"PenWidth":1,"BrushColor":16777215,"BrushStyle":0},' +
      '{"Class":"TReportTextObject","Name":"hLoc","Bounds":{"L":10,"T":307,"R":720,"B":323},"Visible":true,"Text":"4. STORAGE & PHYSICAL INVENTORY LOCATION","FontName":"Segoe UI","FontSize":10,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"vLoc1","Bounds":{"L":10,"T":327,"R":360,"B":343},"Visible":true,"Text":"Rack Location: [STORAGE_RACK]  Shelf: [STORAGE_SHELF]  Bin: [STORAGE_BIN]","FontName":"Segoe UI","FontSize":9,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"vLoc2","Bounds":{"L":370,"T":327,"R":720,"B":343},"Visible":true,"Text":"Full Location: [STORAGE_LOCATION]","FontName":"Segoe UI","FontSize":9,"Transparent":true},' +
      '{"Class":"TReportShapeObject","Name":"boxNotes","Bounds":{"L":0,"T":383,"R":733,"B":465},"Visible":true,"ShapeType":0,"PenColor":13421772,"PenWidth":1,"BrushColor":16777215,"BrushStyle":0},' +
      '{"Class":"TReportTextObject","Name":"hNotes","Bounds":{"L":10,"T":387,"R":720,"B":403},"Visible":true,"Text":"5. OPERATIONAL NOTES & CUTTING HISTORY","FontName":"Segoe UI","FontSize":10,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"vNotes1","Bounds":{"L":10,"T":407,"R":360,"B":423},"Visible":true,"Text":"Die Maker: [DIE_MAKER] | Supplier Ref: [SUPPLIER_REF]","FontName":"Segoe UI","FontSize":9,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"vNotes2","Bounds":{"L":370,"T":407,"R":720,"B":423},"Visible":true,"Text":"Total Run Metres: [TOTAL_RUN_METRES] m","FontName":"Segoe UI","FontSize":9,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"vNotes3","Bounds":{"L":10,"T":427,"R":720,"B":443},"Visible":true,"Text":"Notes / Overrides: [NOTES] [OVERRIDE_REASON]","FontName":"Segoe UI","FontSize":9,"Transparent":true}' +
      ']},' +
      '{"Class":"TReportBand","Name":"BandPageFooter","Bounds":{"L":0,"T":0,"R":733,"B":30},"Visible":true,"BandType":3,"Height":30,"Children":[' +
      '{"Class":"TReportTextObject","Name":"lblFooterNotice","Bounds":{"L":0,"T":6,"R":400,"B":24},"Visible":true,"Text":"DieVix Production Floor Control - Authoritative Rotary Die System","FontName":"Segoe UI","FontSize":8,"FontColor":8421504,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"lblFooterPage","Bounds":{"L":533,"T":6,"R":733,"B":24},"Visible":true,"Text":"Page [Page#] of [TotalPages#]","FontName":"Segoe UI","FontSize":8,"FontColor":8421504,"HAlign":1,"Transparent":true}' +
      ']}' +
      ']}';
  end
  else if (BaseName = 'die_register_catalog.vrt') then
  begin
    Result :=
      '{"Version":2,"Title":"Rotary Die Inventory Register","Author":"DieVix","PageSettings":{"PaperSize":0,"Orientation":1,"MarginLeft":30,"MarginTop":30,"MarginRight":30,"MarginBottom":30,"CustomWidth":1122,"CustomHeight":793},' +
      '"FieldNames":["ID","SERIAL_NO","CUSTOMER_CODE","CUSTOMER_NAME","TEETH","REPEAT_MM","AROUND_SIZE_MM","ACROSS_SIZE_MM","UPS_TEXT","AROUND_GAP_MM","ACROSS_GAP_MM","SHAPE","STATUS_NAME","GAP_POLICY_STATUS","STORAGE_LOCATION"],' +
      '"DataSetNames":["DieList"],"Objects":[' +
      '{"Class":"TReportBand","Name":"BandTitle","Bounds":{"L":0,"T":0,"R":1062,"B":50},"Visible":true,"BandType":0,"Height":50,"Children":[' +
      '{"Class":"TReportTextObject","Name":"txtCatalogTitle","Bounds":{"L":0,"T":6,"R":600,"B":30},"Visible":true,"Text":"DieVix - Rotary Die Inventory Register","FontName":"Segoe UI","FontSize":15,"FontColor":1973790,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"txtCatalogSubtitle","Bounds":{"L":0,"T":30,"R":600,"B":46},"Visible":true,"Text":"Authoritative Tooling Inventory & Cylinder Specification Catalog","FontName":"Segoe UI","FontSize":9,"FontColor":5395026,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"txtReportDate","Bounds":{"L":750,"T":15,"R":1062,"B":35},"Visible":true,"Text":"Report Date: [Date]","FontName":"Segoe UI","FontSize":10,"HAlign":1,"Transparent":true}' +
      ']},' +
      '{"Class":"TReportBand","Name":"BandColHeader","Bounds":{"L":0,"T":0,"R":1062,"B":24},"Visible":true,"BandType":7,"Height":24,"Children":[' +
      '{"Class":"TReportShapeObject","Name":"bgColHeader","Bounds":{"L":0,"T":0,"R":1062,"B":24},"Visible":true,"ShapeType":0,"PenColor":14013909,"PenWidth":1,"BrushColor":15856113,"BrushStyle":0},' +
      '{"Class":"TReportTextObject","Name":"hSerial","Bounds":{"L":6,"T":2,"R":120,"B":22},"Visible":true,"Text":"Serial No","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hCustomer","Bounds":{"L":125,"T":2,"R":260,"B":22},"Visible":true,"Text":"Customer","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hTeeth","Bounds":{"L":265,"T":2,"R":325,"B":22},"Visible":true,"Text":"Teeth","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hRepeat","Bounds":{"L":330,"T":2,"R":410,"B":22},"Visible":true,"Text":"Repeat mm","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hAround","Bounds":{"L":415,"T":2,"R":485,"B":22},"Visible":true,"Text":"Around mm","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hAcross","Bounds":{"L":490,"T":2,"R":560,"B":22},"Visible":true,"Text":"Across mm","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hUps","Bounds":{"L":565,"T":2,"R":635,"B":22},"Visible":true,"Text":"Ups","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hAroundGap","Bounds":{"L":640,"T":2,"R":720,"B":22},"Visible":true,"Text":"Around Gap","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hAcrossGap","Bounds":{"L":725,"T":2,"R":805,"B":22},"Visible":true,"Text":"Across Gap","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hShape","Bounds":{"L":810,"T":2,"R":880,"B":22},"Visible":true,"Text":"Shape","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hStatus","Bounds":{"L":885,"T":2,"R":965,"B":22},"Visible":true,"Text":"Status","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hLocation","Bounds":{"L":970,"T":2,"R":1062,"B":22},"Visible":true,"Text":"Location","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true}' +
      ']},' +
      '{"Class":"TReportBand","Name":"BandDetail","Bounds":{"L":0,"T":0,"R":1062,"B":20},"Visible":true,"BandType":2,"Height":20,"DataSetName":"DieList","Children":[' +
      '{"Class":"TReportTextObject","Name":"dSerial","Bounds":{"L":6,"T":2,"R":120,"B":18},"Visible":true,"Text":"[SERIAL_NO]","FontName":"Segoe UI","FontSize":8,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dCustomer","Bounds":{"L":125,"T":2,"R":260,"B":18},"Visible":true,"Text":"[CUSTOMER_NAME]","FontName":"Segoe UI","FontSize":8,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dTeeth","Bounds":{"L":265,"T":2,"R":325,"B":18},"Visible":true,"Text":"[TEETH] T","FontName":"Segoe UI","FontSize":8,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dRepeat","Bounds":{"L":330,"T":2,"R":410,"B":18},"Visible":true,"Text":"[REPEAT_MM]","FontName":"Segoe UI","FontSize":8,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dAround","Bounds":{"L":415,"T":2,"R":485,"B":18},"Visible":true,"Text":"[AROUND_SIZE_MM]","FontName":"Segoe UI","FontSize":8,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dAcross","Bounds":{"L":490,"T":2,"R":560,"B":18},"Visible":true,"Text":"[ACROSS_SIZE_MM]","FontName":"Segoe UI","FontSize":8,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dUps","Bounds":{"L":565,"T":2,"R":635,"B":18},"Visible":true,"Text":"[UPS_TEXT]","FontName":"Segoe UI","FontSize":8,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dAroundGap","Bounds":{"L":640,"T":2,"R":720,"B":18},"Visible":true,"Text":"[AROUND_GAP_MM]","FontName":"Segoe UI","FontSize":8,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dAcrossGap","Bounds":{"L":725,"T":2,"R":805,"B":18},"Visible":true,"Text":"[ACROSS_GAP_MM]","FontName":"Segoe UI","FontSize":8,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dShape","Bounds":{"L":810,"T":2,"R":880,"B":18},"Visible":true,"Text":"[SHAPE]","FontName":"Segoe UI","FontSize":8,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dStatus","Bounds":{"L":885,"T":2,"R":965,"B":18},"Visible":true,"Text":"[STATUS_NAME]","FontName":"Segoe UI","FontSize":8,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dLocation","Bounds":{"L":970,"T":2,"R":1062,"B":18},"Visible":true,"Text":"[STORAGE_LOCATION]","FontName":"Segoe UI","FontSize":8,"Transparent":true},' +
      '{"Class":"TReportShapeObject","Name":"divRow","Bounds":{"L":0,"T":19,"R":1062,"B":20},"Visible":true,"ShapeType":4,"PenColor":15329769,"PenWidth":1,"BrushColor":15329769,"BrushStyle":0}' +
      ']},' +
      '{"Class":"TReportBand","Name":"BandPageFooter","Bounds":{"L":0,"T":0,"R":1062,"B":25},"Visible":true,"BandType":3,"Height":25,"Children":[' +
      '{"Class":"TReportTextObject","Name":"txtCatFooterNotice","Bounds":{"L":0,"T":4,"R":500,"B":20},"Visible":true,"Text":"DieVix - Rotary Die & Tooling Inventory System","FontName":"Segoe UI","FontSize":8,"FontColor":8421504,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"txtCatPageNum","Bounds":{"L":862,"T":4,"R":1062,"B":20},"Visible":true,"Text":"Page [Page#] of [TotalPages#]","FontName":"Segoe UI","FontSize":8,"FontColor":8421504,"HAlign":1,"Transparent":true}' +
      ']}' +
      ']}';
  end
  else if (BaseName = 'cylinder_fleet_matrix.vrt') then
  begin
    Result :=
      '{"Version":2,"Title":"Machine Fleet Cylinder Matrix","Author":"DieVix","PageSettings":{"PaperSize":0,"Orientation":1,"MarginLeft":30,"MarginTop":30,"MarginRight":30,"MarginBottom":30,"CustomWidth":1122,"CustomHeight":793},' +
      '"FieldNames":["MACHINE_CODE","MACHINE_NAME","PRINT_METHOD","WEB_WIDTH_RANGE","TEETH","PITCH_DESC","REPEAT_MM","REPEAT_INCH","ASSIGNED_STATUS","ACTIVE_DIES_COUNT","NOTES"],' +
      '"DataSetNames":["FleetMatrix"],"Objects":[' +
      '{"Class":"TReportBand","Name":"BandTitle","Bounds":{"L":0,"T":0,"R":1062,"B":50},"Visible":true,"BandType":0,"Height":50,"Children":[' +
      '{"Class":"TReportTextObject","Name":"txtMatrixTitle","Bounds":{"L":0,"T":6,"R":600,"B":30},"Visible":true,"Text":"DieVix - Machine Fleet & Cylinder Tooling Matrix","FontName":"Segoe UI","FontSize":15,"FontColor":1973790,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"txtMatrixSubtitle","Bounds":{"L":0,"T":30,"R":600,"B":46},"Visible":true,"Text":"Press Capability, Cylinder Gear Pitch, Repeat Lengths & Assigned Active Inventory","FontName":"Segoe UI","FontSize":9,"FontColor":5395026,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"txtReportDate","Bounds":{"L":750,"T":15,"R":1062,"B":35},"Visible":true,"Text":"Report Date: [Date]","FontName":"Segoe UI","FontSize":10,"HAlign":1,"Transparent":true}' +
      ']},' +
      '{"Class":"TReportBand","Name":"BandColHeader","Bounds":{"L":0,"T":0,"R":1062,"B":24},"Visible":true,"BandType":7,"Height":24,"Children":[' +
      '{"Class":"TReportShapeObject","Name":"bgColHeader","Bounds":{"L":0,"T":0,"R":1062,"B":24},"Visible":true,"ShapeType":0,"PenColor":14013909,"PenWidth":1,"BrushColor":15856113,"BrushStyle":0},' +
      '{"Class":"TReportTextObject","Name":"hMachine","Bounds":{"L":6,"T":2,"R":220,"B":22},"Visible":true,"Text":"Machine / Press","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hWebWidth","Bounds":{"L":225,"T":2,"R":340,"B":22},"Visible":true,"Text":"Web Width (Min-Max)","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hMethod","Bounds":{"L":345,"T":2,"R":450,"B":22},"Visible":true,"Text":"Print Method","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hTeeth","Bounds":{"L":455,"T":2,"R":540,"B":22},"Visible":true,"Text":"Cylinder Teeth","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hPitch","Bounds":{"L":545,"T":2,"R":630,"B":22},"Visible":true,"Text":"Gear Pitch","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hRepeat","Bounds":{"L":635,"T":2,"R":760,"B":22},"Visible":true,"Text":"Repeat (mm / in)","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hStatus","Bounds":{"L":765,"T":2,"R":870,"B":22},"Visible":true,"Text":"Tooling Status","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hActiveDies","Bounds":{"L":875,"T":2,"R":950,"B":22},"Visible":true,"Text":"Active Dies","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hNotes","Bounds":{"L":955,"T":2,"R":1062,"B":22},"Visible":true,"Text":"Notes / Shelf","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true}' +
      ']},' +
      '{"Class":"TReportBand","Name":"BandMasterData","Bounds":{"L":0,"T":0,"R":1062,"B":20},"Visible":true,"BandType":2,"Height":20,"DataSetName":"FleetMatrix","Children":[' +
      '{"Class":"TReportTextObject","Name":"dMachine","Bounds":{"L":6,"T":2,"R":220,"B":18},"Visible":true,"Text":"[MACHINE_CODE] - [MACHINE_NAME]","FontName":"Segoe UI","FontSize":8,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dWebWidth","Bounds":{"L":225,"T":2,"R":340,"B":18},"Visible":true,"Text":"[WEB_WIDTH_RANGE]","FontName":"Segoe UI","FontSize":8,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dMethod","Bounds":{"L":345,"T":2,"R":450,"B":18},"Visible":true,"Text":"[PRINT_METHOD]","FontName":"Segoe UI","FontSize":8,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dTeeth","Bounds":{"L":455,"T":2,"R":540,"B":18},"Visible":true,"Text":"[TEETH] T","FontName":"Segoe UI","FontSize":8,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dPitch","Bounds":{"L":545,"T":2,"R":630,"B":18},"Visible":true,"Text":"[PITCH_DESC]","FontName":"Segoe UI","FontSize":8,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dRepeat","Bounds":{"L":635,"T":2,"R":760,"B":18},"Visible":true,"Text":"[REPEAT_MM] mm ([REPEAT_INCH]\")","FontName":"Segoe UI","FontSize":8,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dStatus","Bounds":{"L":765,"T":2,"R":870,"B":18},"Visible":true,"Text":"[ASSIGNED_STATUS]","FontName":"Segoe UI","FontSize":8,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dActiveDies","Bounds":{"L":875,"T":2,"R":950,"B":18},"Visible":true,"Text":"[ACTIVE_DIES_COUNT]","FontName":"Segoe UI","FontSize":8,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dNotes","Bounds":{"L":955,"T":2,"R":1062,"B":18},"Visible":true,"Text":"[NOTES]","FontName":"Segoe UI","FontSize":8,"Transparent":true},' +
      '{"Class":"TReportShapeObject","Name":"divRow","Bounds":{"L":0,"T":19,"R":1062,"B":20},"Visible":true,"ShapeType":4,"PenColor":15329769,"PenWidth":1,"BrushColor":15329769,"BrushStyle":0}' +
      ']},' +
      '{"Class":"TReportBand","Name":"BandPageFooter","Bounds":{"L":0,"T":0,"R":1062,"B":25},"Visible":true,"BandType":3,"Height":25,"Children":[' +
      '{"Class":"TReportTextObject","Name":"txtFleetFooterNotice","Bounds":{"L":0,"T":4,"R":500,"B":20},"Visible":true,"Text":"DieVix - Rotary Die & Tooling Fleet Management System","FontName":"Segoe UI","FontSize":8,"FontColor":8421504,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"txtFleetPageNum","Bounds":{"L":862,"T":4,"R":1062,"B":20},"Visible":true,"Text":"Page [Page#] of [TotalPages#]","FontName":"Segoe UI","FontSize":8,"FontColor":8421504,"HAlign":1,"Transparent":true}' +
      ']}' +
      ']}';
  end
  else if (BaseName = 'flatbed_tooling_card.vrt') then
  begin
    Result :=
      '{"Version":2,"Title":"Flatbed Die Tooling Job Bag Card","Author":"DieVix","PageSettings":{"PaperSize":0,"Orientation":0,"MarginLeft":30,"MarginTop":30,"MarginRight":30,"MarginBottom":30,"CustomWidth":793,"CustomHeight":1122},' +
      '"FieldNames":["ID","SERIAL_NO","DESCRIPTION","CATEGORY","CATEGORY_DESC","CUSTOMER_CODE","CUSTOMER_NAME","CUSTOMER_REF","INTERNAL_REF","SUPPLIER_REF","AROUND_SIZE_MM","ACROSS_SIZE_MM","AROUND_UPS","ACROSS_UPS","TOTAL_UPS","AROUND_GAP_MM","ACROSS_GAP_MM","CORNER_RADIUS_MM","SHAPE","PLATE_WIDTH_MM","PLATE_LENGTH_MM","MAX_FEED_STROKE_MM","TOTAL_CUT_AROUND_MM","TOTAL_CUT_ACROSS_MM","CAN_ROTATE","ROTATION_SUPPORT","ROTATION_BADGE","STORAGE_LOCATION","STORAGE_RACK","STORAGE_SHELF","STORAGE_BIN","STATUS_CODE","STATUS_NAME","MEDIA_CODE","MEDIA_NAME","FACE_MATERIAL","LINER_MATERIAL","ADHESIVE_TYPE","TOTAL_CALIPER_UM","DIE_MAKER","TOTAL_IMPRESSIONS","NOTES","CREATED_BY","CREATED_AT"],' +
      '"DataSetNames":["DieData"],"Objects":[' +
      '{"Class":"TReportBand","Name":"BandTitle","Bounds":{"L":0,"T":0,"R":733,"B":90},"Visible":true,"BandType":0,"Height":90,"Children":[' +
      '{"Class":"TReportTextObject","Name":"lblAppTitle","Bounds":{"L":0,"T":4,"R":460,"B":28},"Visible":true,"Text":"DieVix - Flatbed Die Tooling Job Bag Card","FontName":"Segoe UI","FontSize":14,"FontColor":1973790,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"lblSubtitle","Bounds":{"L":0,"T":28,"R":460,"B":44},"Visible":true,"Text":"Authoritative Flatbed Cutting Specification & Production Job Bag Card","FontName":"Segoe UI","FontSize":9,"FontColor":5395026,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"lblHeaderSerial","Bounds":{"L":0,"T":50,"R":460,"B":84},"Visible":true,"Text":"FLATBED SERIAL: [SERIAL_NO]","FontName":"Segoe UI","FontSize":16,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportBarcodeObject","Name":"barSerialCode","Bounds":{"L":480,"T":8,"R":730,"B":78},"Visible":true,"Value":"[SERIAL_NO]","DataField":"SERIAL_NO","Symbology":1,"ShowText":true,"BarColor":0,"BackgroundColor":16777215}' +
      ']},' +
      '{"Class":"TReportBand","Name":"BandMaster","Bounds":{"L":0,"T":0,"R":733,"B":580},"Visible":true,"BandType":8,"Height":580,"DataSetName":"DieData","Children":[' +
      '{"Class":"TReportTextObject","Name":"boxSec1Title","Bounds":{"L":0,"T":8,"R":355,"B":30},"Visible":true,"Text":"1. TOOLING IDENTIFICATION & STATUS","FontName":"Segoe UI","FontSize":10,"FontBold":true,"Transparent":false,"Background":15395562,"BorderVisible":true,"BorderColor":12632256,"PaddingLeft":6},' +
      '{"Class":"TReportTextObject","Name":"boxSec1Body","Bounds":{"L":0,"T":30,"R":355,"B":170},"Visible":true,"Text":"Category: [CATEGORY_DESC]\nCustomer: [CUSTOMER_NAME] ([CUSTOMER_CODE])\nCustomer Ref: [CUSTOMER_REF]\nInternal Ref: [INTERNAL_REF]\nTooling Shape: [SHAPE]\nOperational Status: [STATUS_NAME]\nDie Maker: [DIE_MAKER]\nSupplier Ref: [SUPPLIER_REF]","FontName":"Segoe UI","FontSize":9,"WordWrap":true,"Transparent":true,"BorderVisible":true,"BorderColor":12632256,"PaddingLeft":8,"PaddingTop":8,"PaddingRight":8,"PaddingBottom":8},' +
      '{"Class":"TReportTextObject","Name":"boxSec2Title","Bounds":{"L":375,"T":8,"R":733,"B":30},"Visible":true,"Text":"2. MACHINE ENVELOPE & ROTATION SUPPORT","FontName":"Segoe UI","FontSize":10,"FontBold":true,"Transparent":false,"Background":15395562,"BorderVisible":true,"BorderColor":12632256,"PaddingLeft":6},' +
      '{"Class":"TReportTextObject","Name":"boxSec2Body","Bounds":{"L":375,"T":30,"R":733,"B":170},"Visible":true,"Text":"Rotation Support: [ROTATION_BADGE]\nPlate Envelope: [PLATE_WIDTH_MM] mm (W) x [PLATE_LENGTH_MM] mm (L)\nMax Feed Stroke: [MAX_FEED_STROKE_MM] mm\nTotal Impressions: [TOTAL_IMPRESSIONS] cuts\nStorage Location: [STORAGE_LOCATION]\nStorage Rack: [STORAGE_RACK]\nStorage Shelf / Bin: [STORAGE_SHELF] / [STORAGE_BIN]","FontName":"Segoe UI","FontSize":9,"WordWrap":true,"Transparent":true,"BorderVisible":true,"BorderColor":12632256,"PaddingLeft":8,"PaddingTop":8,"PaddingRight":8,"PaddingBottom":8},' +
      '{"Class":"TReportTextObject","Name":"boxSec3Title","Bounds":{"L":0,"T":185,"R":355,"B":207},"Visible":true,"Text":"3. CAVITY GEOMETRY & IMPOSITION","FontName":"Segoe UI","FontSize":10,"FontBold":true,"Transparent":false,"Background":15395562,"BorderVisible":true,"BorderColor":12632256,"PaddingLeft":6},' +
      '{"Class":"TReportTextObject","Name":"boxSec3Body","Bounds":{"L":0,"T":207,"R":355,"B":345},"Visible":true,"Text":"Around Size (Feed Direction): [AROUND_SIZE_MM] mm\nAcross Size (Plate Width): [ACROSS_SIZE_MM] mm\nCorner Radius: [CORNER_RADIUS_MM] mm\nAround Ups (Cavities): [AROUND_UPS]\nAcross Ups (Lanes): [ACROSS_UPS]\nTotal Impressions: [TOTAL_UPS] Cavities\nAround Gap: [AROUND_GAP_MM] mm\nAcross Gap: [ACROSS_GAP_MM] mm","FontName":"Segoe UI","FontSize":9,"WordWrap":true,"Transparent":true,"BorderVisible":true,"BorderColor":12632256,"PaddingLeft":8,"PaddingTop":8,"PaddingRight":8,"PaddingBottom":8},' +
      '{"Class":"TReportTextObject","Name":"boxSec4Title","Bounds":{"L":375,"T":185,"R":733,"B":207},"Visible":true,"Text":"4. CUTTING FOOTPRINT & SUBSTRATE","FontName":"Segoe UI","FontSize":10,"FontBold":true,"Transparent":false,"Background":15395562,"BorderVisible":true,"BorderColor":12632256,"PaddingLeft":6},' +
      '{"Class":"TReportTextObject","Name":"boxSec4Body","Bounds":{"L":375,"T":207,"R":733,"B":345},"Visible":true,"Text":"Total Cutting Footprint: [TOTAL_CUT_AROUND_MM] mm x [TOTAL_CUT_ACROSS_MM] mm\nTarget Media: [MEDIA_NAME] ([MEDIA_CODE])\nFace Material: [FACE_MATERIAL]\nLiner Material: [LINER_MATERIAL]\nAdhesive Type: [ADHESIVE_TYPE]\nTotal Caliper: [TOTAL_CALIPER_UM] um\nCreated By User: [CREATED_BY]\nCreated Timestamp: [CREATED_AT]","FontName":"Segoe UI","FontSize":9,"WordWrap":true,"Transparent":true,"BorderVisible":true,"BorderColor":12632256,"PaddingLeft":8,"PaddingTop":8,"PaddingRight":8,"PaddingBottom":8},' +
      '{"Class":"TReportTextObject","Name":"boxSec5Title","Bounds":{"L":0,"T":360,"R":733,"B":382},"Visible":true,"Text":"5. OPERATIONAL NOTES & TOOLING SPECIFICATIONS","FontName":"Segoe UI","FontSize":10,"FontBold":true,"Transparent":false,"Background":15395562,"BorderVisible":true,"BorderColor":12632256,"PaddingLeft":6},' +
      '{"Class":"TReportTextObject","Name":"boxSec5Body","Bounds":{"L":0,"T":382,"R":733,"B":480},"Visible":true,"Text":"Description: [DESCRIPTION]\nTooling Notes: [NOTES]","FontName":"Segoe UI","FontSize":9,"WordWrap":true,"Transparent":true,"BorderVisible":true,"BorderColor":12632256,"PaddingLeft":8,"PaddingTop":8,"PaddingRight":8,"PaddingBottom":8},' +
      '{"Class":"TReportTextObject","Name":"boxSignatures","Bounds":{"L":0,"T":495,"R":733,"B":565},"Visible":true,"Text":"Tooling Prep Sign-off: ________________________        Press Operator Mount Sign-off: ________________________\n\nQC Approval Sign-off: ________________________        Job Completed Sign-off: ________________________","FontName":"Segoe UI","FontSize":9,"FontColor":5395026,"Transparent":true,"BorderVisible":true,"BorderColor":14211288,"PaddingLeft":8,"PaddingTop":8,"PaddingRight":8,"PaddingBottom":8}' +
      ']},' +
      '{"Class":"TReportBand","Name":"BandPageFooter","Bounds":{"L":0,"T":0,"R":733,"B":30},"Visible":true,"BandType":3,"Height":30,"Children":[' +
      '{"Class":"TReportTextObject","Name":"txtFooterNotice","Bounds":{"L":0,"T":6,"R":500,"B":24},"Visible":true,"Text":"Generated by DieVix - Confidential Flatbed Die Tooling Specification","FontName":"Segoe UI","FontSize":8,"FontColor":8421504,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"txtPageNum","Bounds":{"L":520,"T":6,"R":733,"B":24},"Visible":true,"Text":"Page [Page#] of [TotalPages#]","FontName":"Segoe UI","FontSize":8,"FontColor":8421504,"HAlign":1,"Transparent":true}' +
      ']}' +
      ']}';
  end
  else if (BaseName = 'flatbed_register_catalog.vrt') then
  begin
    Result :=
      '{"Version":2,"Title":"Flatbed Die Inventory Register","Author":"DieVix","PageSettings":{"PaperSize":0,"Orientation":1,"MarginLeft":30,"MarginTop":30,"MarginRight":30,"MarginBottom":30,"CustomWidth":1122,"CustomHeight":793},' +
      '"FieldNames":["ID","SERIAL_NO","CATEGORY","CATEGORY_NAME","CUSTOMER_CODE","CUSTOMER_NAME","AROUND_SIZE_MM","ACROSS_SIZE_MM","CAVITY_TEXT","AROUND_UPS","ACROSS_UPS","TOTAL_UPS","UPS_TEXT","TOTAL_CUT_AROUND_MM","TOTAL_CUT_ACROSS_MM","CUT_FOOTPRINT_TEXT","PLATE_WIDTH_MM","PLATE_LENGTH_MM","PLATE_SIZE_TEXT","CAN_ROTATE","ROTATION_TEXT","ROTATION_SUPPORT","STATUS_NAME","STATUS_CODE","STORAGE_LOCATION"],' +
      '"DataSetNames":["DieList"],"Objects":[' +
      '{"Class":"TReportBand","Name":"BandTitle","Bounds":{"L":0,"T":0,"R":1062,"B":50},"Visible":true,"BandType":0,"Height":50,"Children":[' +
      '{"Class":"TReportTextObject","Name":"txtCatalogTitle","Bounds":{"L":0,"T":6,"R":600,"B":30},"Visible":true,"Text":"DieVix - Flatbed Die Inventory Register","FontName":"Segoe UI","FontSize":15,"FontColor":1973790,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"txtCatalogSubtitle","Bounds":{"L":0,"T":30,"R":600,"B":46},"Visible":true,"Text":"Authoritative Flatbed Tooling Catalog & Bi-Directional Compatibility Matrix","FontName":"Segoe UI","FontSize":9,"FontColor":5395026,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"txtReportDate","Bounds":{"L":750,"T":15,"R":1062,"B":35},"Visible":true,"Text":"Report Date: [Date]","FontName":"Segoe UI","FontSize":10,"HAlign":1,"Transparent":true}' +
      ']},' +
      '{"Class":"TReportBand","Name":"BandColHeader","Bounds":{"L":0,"T":0,"R":1062,"B":24},"Visible":true,"BandType":7,"Height":24,"BackColor":15395562,"BackColorTransparent":false,"Children":[' +
      '{"Class":"TReportTextObject","Name":"hSerial","Bounds":{"L":0,"T":2,"R":105,"B":22},"Visible":true,"Text":"Serial Number","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true,"PaddingLeft":4},' +
      '{"Class":"TReportTextObject","Name":"hCategory","Bounds":{"L":110,"T":2,"R":195,"B":22},"Visible":true,"Text":"Category","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hCustomer","Bounds":{"L":200,"T":2,"R":340,"B":22},"Visible":true,"Text":"Customer / Owner","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hCavity","Bounds":{"L":345,"T":2,"R":460,"B":22},"Visible":true,"Text":"Cavity (Around x Across)","FontName":"Segoe UI","FontSize":9,"FontBold":true,"HAlign":1,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hUps","Bounds":{"L":465,"T":2,"R":540,"B":22},"Visible":true,"Text":"Ups (Ar x Ac)","FontName":"Segoe UI","FontSize":9,"FontBold":true,"HAlign":2,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hFootprint","Bounds":{"L":545,"T":2,"R":660,"B":22},"Visible":true,"Text":"Cut Footprint (mm)","FontName":"Segoe UI","FontSize":9,"FontBold":true,"HAlign":1,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hPlate","Bounds":{"L":665,"T":2,"R":770,"B":22},"Visible":true,"Text":"Plate Size (mm)","FontName":"Segoe UI","FontSize":9,"FontBold":true,"HAlign":1,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hRotation","Bounds":{"L":775,"T":2,"R":875,"B":22},"Visible":true,"Text":"Rotation","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hStatus","Bounds":{"L":880,"T":2,"R":955,"B":22},"Visible":true,"Text":"Status","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"hLocation","Bounds":{"L":960,"T":2,"R":1062,"B":22},"Visible":true,"Text":"Storage Location","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true}' +
      ']},' +
      '{"Class":"TReportBand","Name":"BandDetail","Bounds":{"L":0,"T":0,"R":1062,"B":20},"Visible":true,"BandType":8,"Height":20,"DataSetName":"DieList","Children":[' +
      '{"Class":"TReportTextObject","Name":"dSerial","Bounds":{"L":0,"T":2,"R":105,"B":18},"Visible":true,"Text":"[SERIAL_NO]","FontName":"Segoe UI","FontSize":8,"FontBold":true,"Transparent":true,"PaddingLeft":4},' +
      '{"Class":"TReportTextObject","Name":"dCategory","Bounds":{"L":110,"T":2,"R":195,"B":18},"Visible":true,"Text":"[CATEGORY_NAME]","FontName":"Segoe UI","FontSize":8,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dCustomer","Bounds":{"L":200,"T":2,"R":340,"B":18},"Visible":true,"Text":"[CUSTOMER_NAME]","FontName":"Segoe UI","FontSize":8,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dCavity","Bounds":{"L":345,"T":2,"R":460,"B":18},"Visible":true,"Text":"[CAVITY_TEXT]","FontName":"Segoe UI","FontSize":8,"HAlign":1,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dUps","Bounds":{"L":465,"T":2,"R":540,"B":18},"Visible":true,"Text":"[UPS_TEXT]","FontName":"Segoe UI","FontSize":8,"HAlign":2,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dFootprint","Bounds":{"L":545,"T":2,"R":660,"B":18},"Visible":true,"Text":"[CUT_FOOTPRINT_TEXT]","FontName":"Segoe UI","FontSize":8,"HAlign":1,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dPlate","Bounds":{"L":665,"T":2,"R":770,"B":18},"Visible":true,"Text":"[PLATE_SIZE_TEXT]","FontName":"Segoe UI","FontSize":8,"HAlign":1,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dRotation","Bounds":{"L":775,"T":2,"R":875,"B":18},"Visible":true,"Text":"[ROTATION_TEXT]","FontName":"Segoe UI","FontSize":8,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dStatus","Bounds":{"L":880,"T":2,"R":955,"B":18},"Visible":true,"Text":"[STATUS_NAME]","FontName":"Segoe UI","FontSize":8,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"dLocation","Bounds":{"L":960,"T":2,"R":1062,"B":18},"Visible":true,"Text":"[STORAGE_LOCATION]","FontName":"Segoe UI","FontSize":8,"Transparent":true}' +
      ']},' +
      '{"Class":"TReportBand","Name":"BandSummary","Bounds":{"L":0,"T":0,"R":1062,"B":35},"Visible":true,"BandType":4,"Height":35,"BackColor":15790320,"BackColorTransparent":false,"Children":[' +
      '{"Class":"TReportTextObject","Name":"txtSummaryTotals","Bounds":{"L":10,"T":8,"R":1050,"B":26},"Visible":true,"Text":"Summary Statistics: [Param.TotalCount] Total Flatbed Dies Listed   |   [Param.RollCount] Rollform Dies   |   [Param.SheetCount] Sheetform Dies   |   [Param.BiDirectionalCount] Bi-Directional Dies","FontName":"Segoe UI","FontSize":9,"FontBold":true,"Transparent":true}' +
      ']},' +
      '{"Class":"TReportBand","Name":"BandPageFooter","Bounds":{"L":0,"T":0,"R":1062,"B":25},"Visible":true,"BandType":3,"Height":25,"Children":[' +
      '{"Class":"TReportTextObject","Name":"txtCatFooterNotice","Bounds":{"L":0,"T":4,"R":500,"B":20},"Visible":true,"Text":"DieVix - Flatbed Die & Tooling Inventory System","FontName":"Segoe UI","FontSize":8,"FontColor":8421504,"Transparent":true},' +
      '{"Class":"TReportTextObject","Name":"txtCatPageNum","Bounds":{"L":862,"T":4,"R":1062,"B":20},"Visible":true,"Text":"Page [Page#] of [TotalPages#]","FontName":"Segoe UI","FontSize":8,"FontColor":8421504,"HAlign":1,"Transparent":true}' +
      ']}' +
      ']}';
  end
  else
    Result := '{}';
end;

function TDieVixReportService.ResolveTemplate(const AReportFileName: string): string;
var
  Cand: string;
  ExeDir: string;
begin
  Result := '';
  ExeDir := ExtractFilePath(ParamStr(0));

  // 1. Explicitly configured custom ReportsPath
  if (FReportsPath <> '') then
  begin
    Cand := TPath.Combine(FReportsPath, AReportFileName);
    if FileExists(Cand) then
      Exit(TFile.ReadAllText(Cand, TEncoding.UTF8));
  end;

  // 2. Relative to executable
  Cand := TPath.GetFullPath(TPath.Combine(ExeDir, 'reports\' + AReportFileName));
  if FileExists(Cand) then
    Exit(TFile.ReadAllText(Cand, TEncoding.UTF8));

  // 3. One folder up (e.g. output dir bin\Win32\Debug\..\..\reports)
  Cand := TPath.GetFullPath(TPath.Combine(ExeDir, '..\reports\' + AReportFileName));
  if FileExists(Cand) then
    Exit(TFile.ReadAllText(Cand, TEncoding.UTF8));

  // 4. Two folders up (e.g. tests\bin\..\..\reports)
  Cand := TPath.GetFullPath(TPath.Combine(ExeDir, '..\..\reports\' + AReportFileName));
  if FileExists(Cand) then
    Exit(TFile.ReadAllText(Cand, TEncoding.UTF8));

  // 5. Current working directory
  Cand := TPath.GetFullPath(TPath.Combine(GetCurrentDir, 'reports\' + AReportFileName));
  if FileExists(Cand) then
    Exit(TFile.ReadAllText(Cand, TEncoding.UTF8));

  // 6. Direct filename in current directory
  if FileExists(AReportFileName) then
    Exit(TFile.ReadAllText(AReportFileName, TEncoding.UTF8));

  // 7. Fallback to embedded template constant
  Result := GetEmbeddedTemplate(AReportFileName);
end;

function TDieVixReportService.ExecuteReport(
  const AReportFileName: string;
  const ADataSetName: string;
  const AQry: TFDQuery;
  const AAction: TReportAction;
  const AOutFilePath: string;
  AParameters: TStrings
): Boolean;
var
  Report: TVittixReport;
  UDS: TVittixUserDataSet;
  JSON: string;
  OutDir: string;
begin
  Result := False;
  JSON := ResolveTemplate(AReportFileName);
  if Trim(JSON) = '' then
    raise Exception.Create('Unable to load report template: ' + AReportFileName);

  if (AOutFilePath <> '') then
  begin
    OutDir := ExtractFilePath(AOutFilePath);
    if (OutDir <> '') and not DirectoryExists(OutDir) then
      ForceDirectories(OutDir);
  end;

  Report := TVittixReport.Create(nil);
  try
    UDS := TVittixUserDataSet.Create(Report);
    UDS.Name := ADataSetName;
    UDS.DataSet := AQry;
    Report.RegisterUserDataSet(UDS);
    Report.ReportJSON := JSON;
    if Assigned(AParameters) then
      Report.Parameters.Assign(AParameters);

    case AAction of
      raPreview:
        begin
          Report.Execute;
          Result := True;
        end;

      raVectorPdf:
        begin
          if FileExists(AOutFilePath) then
            DeleteFile(AOutFilePath);
          Report.ExportToVectorPDF(AOutFilePath);
          Result := FileExists(AOutFilePath);
        end;

      raXlsx:
        begin
          if FileExists(AOutFilePath) then
            DeleteFile(AOutFilePath);
          Report.ExportToXLSX(AOutFilePath);
          Result := FileExists(AOutFilePath);
        end;
    end;
  finally
    Report.Free;
  end;
end;

{ 1. Die Tooling Job Bag Card }

procedure TDieVixReportService.PreviewToolingCard(const ADieID: Integer);
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'SELECT ' +
      '  D.ID, ' +
      '  D.SERIAL_NO, ' +
      '  COALESCE(C.CODE, '''') AS CUSTOMER_CODE, ' +
      '  COALESCE(D.CUSTOMER_NAME, '''') AS CUSTOMER_NAME, ' +
      '  COALESCE(D.CUSTOMER_REF, '''') AS CUSTOMER_REF, ' +
      '  D.TEETH, ' +
      '  D.PITCH_UM, ' +
      '  D.REPEAT_MM, ' +
      '  D.REPEAT_INCH, ' +
      '  D.AROUND_SIZE_MM, ' +
      '  D.ACROSS_SIZE_MM, ' +
      '  D.AROUND_UPS, ' +
      '  D.ACROSS_UPS, ' +
      '  (D.AROUND_UPS * D.ACROSS_UPS) AS TOTAL_UPS, ' +
      '  D.AROUND_GAP_MM, ' +
      '  D.ACROSS_GAP_MM, ' +
      '  D.CORNER_RADIUS_MM, ' +
      '  D.SHAPE, ' +
      '  COALESCE(D.CUT_TYPE, '''') AS CUT_TYPE, ' +
      '  D.STATUS_CODE, ' +
      '  COALESCE(D.STATUS_NAME, '''') AS STATUS_NAME, ' +
      '  D.GAP_POLICY_STATUS, ' +
      '  COALESCE(D.STORAGE_LOCATION, '''') AS STORAGE_LOCATION, ' +
      '  COALESCE(D.STORAGE_RACK, '''') AS STORAGE_RACK, ' +
      '  COALESCE(D.STORAGE_SHELF, '''') AS STORAGE_SHELF, ' +
      '  COALESCE(D.STORAGE_BIN, '''') AS STORAGE_BIN, ' +
      '  COALESCE(M.CODE, '''') AS MEDIA_CODE, ' +
      '  COALESCE(D.MEDIA_NAME, '''') AS MEDIA_NAME, ' +
      '  COALESCE(M.FACE_MATERIAL, '''') AS FACE_MATERIAL, ' +
      '  COALESCE(M.LINER_MATERIAL, '''') AS LINER_MATERIAL, ' +
      '  COALESCE(M.ADHESIVE_TYPE, '''') AS ADHESIVE_TYPE, ' +
      '  COALESCE(M.TOTAL_CALIPER_UM, 0) AS TOTAL_CALIPER_UM, ' +
      '  COALESCE(D.DIE_MAKER, '''') AS DIE_MAKER, ' +
      '  COALESCE(D.SUPPLIER_REF, '''') AS SUPPLIER_REF, ' +
      '  COALESCE(D.TOTAL_RUN_METRES, 0) AS TOTAL_RUN_METRES, ' +
      '  COALESCE(D.OVERRIDE_REASON, '''') AS OVERRIDE_REASON, ' +
      '  COALESCE(D.NOTES, '''') AS NOTES, ' +
      '  COALESCE(D.CREATED_BY, '''') AS CREATED_BY, ' +
      '  CAST(D.CREATED_AT AS VARCHAR(25)) AS CREATED_AT ' +
      'FROM V_DIE_CATALOG D ' +
      'LEFT JOIN CUSTOMER C ON D.CUSTOMER_ID = C.ID ' +
      'LEFT JOIN MEDIA M ON D.MEDIA_ID = M.ID ' +
      'WHERE D.ID = :ID';
    Qry.ParamByName('ID').AsInteger := ADieID;
    Qry.Open;
    if Qry.IsEmpty then
      raise Exception.CreateFmt('Die tooling record with ID %d not found.', [ADieID]);

    ExecuteReport('die_tooling_card.vrt', 'DieData', Qry, raPreview);
  finally
    Qry.Free;
  end;
end;

function TDieVixReportService.ExportToolingCardPdf(const ADieID: Integer; const AOutPdfPath: string): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'SELECT ' +
      '  D.ID, ' +
      '  D.SERIAL_NO, ' +
      '  COALESCE(C.CODE, '''') AS CUSTOMER_CODE, ' +
      '  COALESCE(D.CUSTOMER_NAME, '''') AS CUSTOMER_NAME, ' +
      '  COALESCE(D.CUSTOMER_REF, '''') AS CUSTOMER_REF, ' +
      '  D.TEETH, ' +
      '  D.PITCH_UM, ' +
      '  D.REPEAT_MM, ' +
      '  D.REPEAT_INCH, ' +
      '  D.AROUND_SIZE_MM, ' +
      '  D.ACROSS_SIZE_MM, ' +
      '  D.AROUND_UPS, ' +
      '  D.ACROSS_UPS, ' +
      '  (D.AROUND_UPS * D.ACROSS_UPS) AS TOTAL_UPS, ' +
      '  D.AROUND_GAP_MM, ' +
      '  D.ACROSS_GAP_MM, ' +
      '  D.CORNER_RADIUS_MM, ' +
      '  D.SHAPE, ' +
      '  COALESCE(D.CUT_TYPE, '''') AS CUT_TYPE, ' +
      '  D.STATUS_CODE, ' +
      '  COALESCE(D.STATUS_NAME, '''') AS STATUS_NAME, ' +
      '  D.GAP_POLICY_STATUS, ' +
      '  COALESCE(D.STORAGE_LOCATION, '''') AS STORAGE_LOCATION, ' +
      '  COALESCE(D.STORAGE_RACK, '''') AS STORAGE_RACK, ' +
      '  COALESCE(D.STORAGE_SHELF, '''') AS STORAGE_SHELF, ' +
      '  COALESCE(D.STORAGE_BIN, '''') AS STORAGE_BIN, ' +
      '  COALESCE(M.CODE, '''') AS MEDIA_CODE, ' +
      '  COALESCE(D.MEDIA_NAME, '''') AS MEDIA_NAME, ' +
      '  COALESCE(M.FACE_MATERIAL, '''') AS FACE_MATERIAL, ' +
      '  COALESCE(M.LINER_MATERIAL, '''') AS LINER_MATERIAL, ' +
      '  COALESCE(M.ADHESIVE_TYPE, '''') AS ADHESIVE_TYPE, ' +
      '  COALESCE(M.TOTAL_CALIPER_UM, 0) AS TOTAL_CALIPER_UM, ' +
      '  COALESCE(D.DIE_MAKER, '''') AS DIE_MAKER, ' +
      '  COALESCE(D.SUPPLIER_REF, '''') AS SUPPLIER_REF, ' +
      '  COALESCE(D.TOTAL_RUN_METRES, 0) AS TOTAL_RUN_METRES, ' +
      '  COALESCE(D.OVERRIDE_REASON, '''') AS OVERRIDE_REASON, ' +
      '  COALESCE(D.NOTES, '''') AS NOTES, ' +
      '  COALESCE(D.CREATED_BY, '''') AS CREATED_BY, ' +
      '  CAST(D.CREATED_AT AS VARCHAR(25)) AS CREATED_AT ' +
      'FROM V_DIE_CATALOG D ' +
      'LEFT JOIN CUSTOMER C ON D.CUSTOMER_ID = C.ID ' +
      'LEFT JOIN MEDIA M ON D.MEDIA_ID = M.ID ' +
      'WHERE D.ID = :ID';
    Qry.ParamByName('ID').AsInteger := ADieID;
    Qry.Open;
    if Qry.IsEmpty then
      raise Exception.CreateFmt('Die tooling record with ID %d not found.', [ADieID]);

    Result := ExecuteReport('die_tooling_card.vrt', 'DieData', Qry, raVectorPdf, AOutPdfPath);
  finally
    Qry.Free;
  end;
end;

{ 2. Die Master Register Catalog }

procedure TDieVixReportService.PreviewRegisterCatalog(const AFilter: TDieSearchFilter);
var
  Qry: TFDQuery;
  Sql: string;
begin
  Qry := CreateQuery;
  try
    Sql :=
      'SELECT ' +
      '  D.ID, ' +
      '  D.SERIAL_NO, ' +
      '  COALESCE(C.CODE, '''') AS CUSTOMER_CODE, ' +
      '  COALESCE(D.CUSTOMER_NAME, '''') AS CUSTOMER_NAME, ' +
      '  D.TEETH, ' +
      '  D.REPEAT_MM, ' +
      '  D.AROUND_SIZE_MM, ' +
      '  D.ACROSS_SIZE_MM, ' +
      '  CAST(D.AROUND_UPS AS VARCHAR(10)) || '' x '' || CAST(D.ACROSS_UPS AS VARCHAR(10)) AS UPS_TEXT, ' +
      '  D.AROUND_GAP_MM, ' +
      '  D.ACROSS_GAP_MM, ' +
      '  D.SHAPE, ' +
      '  COALESCE(D.STATUS_NAME, '''') AS STATUS_NAME, ' +
      '  D.GAP_POLICY_STATUS, ' +
      '  COALESCE(D.STORAGE_LOCATION, '''') AS STORAGE_LOCATION ' +
      'FROM V_DIE_CATALOG D ' +
      'LEFT JOIN CUSTOMER C ON D.CUSTOMER_ID = C.ID ' +
      'WHERE (1 = 1) ';

    if Trim(AFilter.SearchText) <> '' then
      Sql := Sql + ' AND (UPPER(D.SERIAL_NO) LIKE :ST OR UPPER(D.CUSTOMER_NAME) LIKE :ST) ';
    if AFilter.CustomerID > 0 then
      Sql := Sql + ' AND (D.CUSTOMER_ID = :CUSTID) ';
    if AFilter.Teeth > 0 then
      Sql := Sql + ' AND (D.TEETH = :TEETH) ';
    if AFilter.MediaID > 0 then
      Sql := Sql + ' AND (D.MEDIA_ID = :MEDIAID) ';
    if Trim(AFilter.StatusCode) <> '' then
      Sql := Sql + ' AND (D.STATUS_CODE = :STATUS) ';
    if Trim(AFilter.Shape) <> '' then
      Sql := Sql + ' AND (D.SHAPE = :SHAPE) ';
    if Trim(AFilter.StorageLocation) <> '' then
      Sql := Sql + ' AND (UPPER(D.STORAGE_LOCATION) LIKE :LOC) ';
    if AFilter.OnlySub3mm then
      Sql := Sql + ' AND (D.AROUND_GAP_MM < 3.000) ';

    if AFilter.ActiveOnly then
      Sql := Sql + ' AND (D.STATUS_CODE IN (''ACTIVE'', ''AVAILABLE'', ''IN_USE'')) '
    else if Trim(AFilter.StatusCode) <> '' then
      Sql := Sql + ' AND (D.STATUS_CODE = :STATUS) '
    else if not AFilter.IncludeArchived then
      Sql := Sql + ' AND (D.STATUS_CODE <> ''ARCHIVED'') ';

    Sql := Sql + ' ORDER BY D.SERIAL_NO ASC';

    Qry.SQL.Text := Sql;
    if Trim(AFilter.SearchText) <> '' then
      Qry.ParamByName('ST').AsString := '%' + UpperCase(Trim(AFilter.SearchText)) + '%';
    if AFilter.CustomerID > 0 then
      Qry.ParamByName('CUSTID').AsInteger := AFilter.CustomerID;
    if AFilter.Teeth > 0 then
      Qry.ParamByName('TEETH').AsInteger := AFilter.Teeth;
    if AFilter.MediaID > 0 then
      Qry.ParamByName('MEDIAID').AsInteger := AFilter.MediaID;
    if Trim(AFilter.StatusCode) <> '' then
      Qry.ParamByName('STATUS').AsString := AFilter.StatusCode;
    if Trim(AFilter.Shape) <> '' then
      Qry.ParamByName('SHAPE').AsString := AFilter.Shape;
    if Trim(AFilter.StorageLocation) <> '' then
      Qry.ParamByName('LOC').AsString := '%' + UpperCase(Trim(AFilter.StorageLocation)) + '%';

    Qry.Open;
    ExecuteReport('die_register_catalog.vrt', 'DieList', Qry, raPreview);
  finally
    Qry.Free;
  end;
end;

function TDieVixReportService.ExportRegisterCatalogPdf(const AFilter: TDieSearchFilter; const AOutPdfPath: string): Boolean;
var
  Qry: TFDQuery;
  Sql: string;
begin
  Qry := CreateQuery;
  try
    Sql :=
      'SELECT ' +
      '  D.ID, ' +
      '  D.SERIAL_NO, ' +
      '  COALESCE(C.CODE, '''') AS CUSTOMER_CODE, ' +
      '  COALESCE(D.CUSTOMER_NAME, '''') AS CUSTOMER_NAME, ' +
      '  D.TEETH, ' +
      '  D.REPEAT_MM, ' +
      '  D.AROUND_SIZE_MM, ' +
      '  D.ACROSS_SIZE_MM, ' +
      '  CAST(D.AROUND_UPS AS VARCHAR(10)) || '' x '' || CAST(D.ACROSS_UPS AS VARCHAR(10)) AS UPS_TEXT, ' +
      '  D.AROUND_GAP_MM, ' +
      '  D.ACROSS_GAP_MM, ' +
      '  D.SHAPE, ' +
      '  COALESCE(D.STATUS_NAME, '''') AS STATUS_NAME, ' +
      '  D.GAP_POLICY_STATUS, ' +
      '  COALESCE(D.STORAGE_LOCATION, '''') AS STORAGE_LOCATION ' +
      'FROM V_DIE_CATALOG D ' +
      'LEFT JOIN CUSTOMER C ON D.CUSTOMER_ID = C.ID ' +
      'WHERE (1 = 1) ';

    if Trim(AFilter.SearchText) <> '' then
      Sql := Sql + ' AND (UPPER(D.SERIAL_NO) LIKE :ST OR UPPER(D.CUSTOMER_NAME) LIKE :ST) ';
    if AFilter.CustomerID > 0 then
      Sql := Sql + ' AND (D.CUSTOMER_ID = :CUSTID) ';
    if AFilter.Teeth > 0 then
      Sql := Sql + ' AND (D.TEETH = :TEETH) ';
    if AFilter.MediaID > 0 then
      Sql := Sql + ' AND (D.MEDIA_ID = :MEDIAID) ';
    if Trim(AFilter.StatusCode) <> '' then
      Sql := Sql + ' AND (D.STATUS_CODE = :STATUS) ';
    if Trim(AFilter.Shape) <> '' then
      Sql := Sql + ' AND (D.SHAPE = :SHAPE) ';
    if Trim(AFilter.StorageLocation) <> '' then
      Sql := Sql + ' AND (UPPER(D.STORAGE_LOCATION) LIKE :LOC) ';
    if AFilter.OnlySub3mm then
      Sql := Sql + ' AND (D.AROUND_GAP_MM < 3.000) ';

    if AFilter.ActiveOnly then
      Sql := Sql + ' AND (D.STATUS_CODE IN (''ACTIVE'', ''AVAILABLE'', ''IN_USE'')) '
    else if Trim(AFilter.StatusCode) <> '' then
      Sql := Sql + ' AND (D.STATUS_CODE = :STATUS) '
    else if not AFilter.IncludeArchived then
      Sql := Sql + ' AND (D.STATUS_CODE <> ''ARCHIVED'') ';

    Sql := Sql + ' ORDER BY D.SERIAL_NO ASC';

    Qry.SQL.Text := Sql;
    if Trim(AFilter.SearchText) <> '' then
      Qry.ParamByName('ST').AsString := '%' + UpperCase(Trim(AFilter.SearchText)) + '%';
    if AFilter.CustomerID > 0 then
      Qry.ParamByName('CUSTID').AsInteger := AFilter.CustomerID;
    if AFilter.Teeth > 0 then
      Qry.ParamByName('TEETH').AsInteger := AFilter.Teeth;
    if AFilter.MediaID > 0 then
      Qry.ParamByName('MEDIAID').AsInteger := AFilter.MediaID;
    if Trim(AFilter.StatusCode) <> '' then
      Qry.ParamByName('STATUS').AsString := AFilter.StatusCode;
    if Trim(AFilter.Shape) <> '' then
      Qry.ParamByName('SHAPE').AsString := AFilter.Shape;
    if Trim(AFilter.StorageLocation) <> '' then
      Qry.ParamByName('LOC').AsString := '%' + UpperCase(Trim(AFilter.StorageLocation)) + '%';

    Qry.Open;
    Result := ExecuteReport('die_register_catalog.vrt', 'DieList', Qry, raVectorPdf, AOutPdfPath);
  finally
    Qry.Free;
  end;
end;

function TDieVixReportService.ExportRegisterCatalogXlsx(const AFilter: TDieSearchFilter; const AOutXlsxPath: string): Boolean;
var
  Qry: TFDQuery;
  Sql: string;
begin
  Qry := CreateQuery;
  try
    Sql :=
      'SELECT ' +
      '  D.ID, ' +
      '  D.SERIAL_NO, ' +
      '  COALESCE(C.CODE, '''') AS CUSTOMER_CODE, ' +
      '  COALESCE(D.CUSTOMER_NAME, '''') AS CUSTOMER_NAME, ' +
      '  D.TEETH, ' +
      '  D.REPEAT_MM, ' +
      '  D.AROUND_SIZE_MM, ' +
      '  D.ACROSS_SIZE_MM, ' +
      '  CAST(D.AROUND_UPS AS VARCHAR(10)) || '' x '' || CAST(D.ACROSS_UPS AS VARCHAR(10)) AS UPS_TEXT, ' +
      '  D.AROUND_GAP_MM, ' +
      '  D.ACROSS_GAP_MM, ' +
      '  D.SHAPE, ' +
      '  COALESCE(D.STATUS_NAME, '''') AS STATUS_NAME, ' +
      '  D.GAP_POLICY_STATUS, ' +
      '  COALESCE(D.STORAGE_LOCATION, '''') AS STORAGE_LOCATION ' +
      'FROM V_DIE_CATALOG D ' +
      'LEFT JOIN CUSTOMER C ON D.CUSTOMER_ID = C.ID ' +
      'WHERE (1 = 1) ';

    if Trim(AFilter.SearchText) <> '' then
      Sql := Sql + ' AND (UPPER(D.SERIAL_NO) LIKE :ST OR UPPER(D.CUSTOMER_NAME) LIKE :ST) ';
    if AFilter.CustomerID > 0 then
      Sql := Sql + ' AND (D.CUSTOMER_ID = :CUSTID) ';
    if AFilter.Teeth > 0 then
      Sql := Sql + ' AND (D.TEETH = :TEETH) ';
    if AFilter.MediaID > 0 then
      Sql := Sql + ' AND (D.MEDIA_ID = :MEDIAID) ';
    if Trim(AFilter.StatusCode) <> '' then
      Sql := Sql + ' AND (D.STATUS_CODE = :STATUS) ';
    if Trim(AFilter.Shape) <> '' then
      Sql := Sql + ' AND (D.SHAPE = :SHAPE) ';
    if Trim(AFilter.StorageLocation) <> '' then
      Sql := Sql + ' AND (UPPER(D.STORAGE_LOCATION) LIKE :LOC) ';
    if AFilter.OnlySub3mm then
      Sql := Sql + ' AND (D.AROUND_GAP_MM < 3.000) ';

    if AFilter.ActiveOnly then
      Sql := Sql + ' AND (D.STATUS_CODE IN (''ACTIVE'', ''AVAILABLE'', ''IN_USE'')) '
    else if Trim(AFilter.StatusCode) <> '' then
      Sql := Sql + ' AND (D.STATUS_CODE = :STATUS) '
    else if not AFilter.IncludeArchived then
      Sql := Sql + ' AND (D.STATUS_CODE <> ''ARCHIVED'') ';

    Sql := Sql + ' ORDER BY D.SERIAL_NO ASC';

    Qry.SQL.Text := Sql;
    if Trim(AFilter.SearchText) <> '' then
      Qry.ParamByName('ST').AsString := '%' + UpperCase(Trim(AFilter.SearchText)) + '%';
    if AFilter.CustomerID > 0 then
      Qry.ParamByName('CUSTID').AsInteger := AFilter.CustomerID;
    if AFilter.Teeth > 0 then
      Qry.ParamByName('TEETH').AsInteger := AFilter.Teeth;
    if AFilter.MediaID > 0 then
      Qry.ParamByName('MEDIAID').AsInteger := AFilter.MediaID;
    if Trim(AFilter.StatusCode) <> '' then
      Qry.ParamByName('STATUS').AsString := AFilter.StatusCode;
    if Trim(AFilter.Shape) <> '' then
      Qry.ParamByName('SHAPE').AsString := AFilter.Shape;
    if Trim(AFilter.StorageLocation) <> '' then
      Qry.ParamByName('LOC').AsString := '%' + UpperCase(Trim(AFilter.StorageLocation)) + '%';

    Qry.Open;
    Result := ExecuteReport('die_register_catalog.vrt', 'DieList', Qry, raXlsx, AOutXlsxPath);
  finally
    Qry.Free;
  end;
end;

{ 3. Machine Fleet Cylinder Tooling Matrix }

procedure TDieVixReportService.PreviewFleetMatrix;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'SELECT ' +
      '  M.CODE AS MACHINE_CODE, ' +
      '  M.NAME AS MACHINE_NAME, ' +
      '  COALESCE(M.PRINT_METHOD, ''Flexo'') AS PRINT_METHOD, ' +
      '  CAST(M.MIN_WEB_WIDTH_MM AS VARCHAR(10)) || '' - '' || CAST(M.MAX_WEB_WIDTH_MM AS VARCHAR(10)) || '' mm'' AS WEB_WIDTH_RANGE, ' +
      '  CS.TEETH, ' +
      '  CASE ' +
      '    WHEN CS.PITCH_UM = 3175 THEN ''3.175 mm (1/8")'' ' +
      '    ELSE CAST(CAST(CS.PITCH_UM / 1000.0 AS NUMERIC(9,3)) AS VARCHAR(20)) || '' mm'' ' +
      '  END AS PITCH_DESC, ' +
      '  CS.REPEAT_MM, ' +
      '  CS.REPEAT_INCH, ' +
      '  CASE ' +
      '    WHEN MC.MACHINE_ID IS NOT NULL THEN ''ASSIGNED'' ' +
      '    ELSE ''AVAILABLE'' ' +
      '  END AS ASSIGNED_STATUS, ' +
      '  (SELECT COUNT(*) FROM DIE D WHERE D.TEETH = CS.TEETH AND D.STATUS_CODE <> ''ARCHIVED'') AS ACTIVE_DIES_COUNT, ' +
      '  COALESCE(CS.NOTES, M.NOTES, '''') AS NOTES ' +
      'FROM MACHINE M ' +
      'CROSS JOIN CYLINDER_SIZE CS ' +
      'LEFT JOIN MACHINE_CYLINDER MC ON (MC.MACHINE_ID = M.ID AND MC.TEETH = CS.TEETH) ' +
      'WHERE M.IS_ACTIVE = 1 AND CS.IS_ACTIVE = 1 ' +
      'ORDER BY M.CODE, CS.TEETH';
    Qry.Open;
    ExecuteReport('cylinder_fleet_matrix.vrt', 'FleetMatrix', Qry, raPreview);
  finally
    Qry.Free;
  end;
end;

function TDieVixReportService.ExportFleetMatrixPdf(const AOutPdfPath: string): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'SELECT ' +
      '  M.CODE AS MACHINE_CODE, ' +
      '  M.NAME AS MACHINE_NAME, ' +
      '  COALESCE(M.PRINT_METHOD, ''Flexo'') AS PRINT_METHOD, ' +
      '  CAST(M.MIN_WEB_WIDTH_MM AS VARCHAR(10)) || '' - '' || CAST(M.MAX_WEB_WIDTH_MM AS VARCHAR(10)) || '' mm'' AS WEB_WIDTH_RANGE, ' +
      '  CS.TEETH, ' +
      '  CASE ' +
      '    WHEN CS.PITCH_UM = 3175 THEN ''3.175 mm (1/8")'' ' +
      '    ELSE CAST(CAST(CS.PITCH_UM / 1000.0 AS NUMERIC(9,3)) AS VARCHAR(20)) || '' mm'' ' +
      '  END AS PITCH_DESC, ' +
      '  CS.REPEAT_MM, ' +
      '  CS.REPEAT_INCH, ' +
      '  CASE ' +
      '    WHEN MC.MACHINE_ID IS NOT NULL THEN ''ASSIGNED'' ' +
      '    ELSE ''AVAILABLE'' ' +
      '  END AS ASSIGNED_STATUS, ' +
      '  (SELECT COUNT(*) FROM DIE D WHERE D.TEETH = CS.TEETH AND D.STATUS_CODE <> ''ARCHIVED'') AS ACTIVE_DIES_COUNT, ' +
      '  COALESCE(CS.NOTES, M.NOTES, '''') AS NOTES ' +
      'FROM MACHINE M ' +
      'CROSS JOIN CYLINDER_SIZE CS ' +
      'LEFT JOIN MACHINE_CYLINDER MC ON (MC.MACHINE_ID = M.ID AND MC.TEETH = CS.TEETH) ' +
      'WHERE M.IS_ACTIVE = 1 AND CS.IS_ACTIVE = 1 ' +
      'ORDER BY M.CODE, CS.TEETH';
    Qry.Open;
    Result := ExecuteReport('cylinder_fleet_matrix.vrt', 'FleetMatrix', Qry, raVectorPdf, AOutPdfPath);
  finally
    Qry.Free;
  end;
end;

function TDieVixReportService.ExportFleetMatrixXlsx(const AOutXlsxPath: string): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'SELECT ' +
      '  M.CODE AS MACHINE_CODE, ' +
      '  M.NAME AS MACHINE_NAME, ' +
      '  COALESCE(M.PRINT_METHOD, ''Flexo'') AS PRINT_METHOD, ' +
      '  CAST(M.MIN_WEB_WIDTH_MM AS VARCHAR(10)) || '' - '' || CAST(M.MAX_WEB_WIDTH_MM AS VARCHAR(10)) || '' mm'' AS WEB_WIDTH_RANGE, ' +
      '  CS.TEETH, ' +
      '  CASE ' +
      '    WHEN CS.PITCH_UM = 3175 THEN ''3.175 mm (1/8")'' ' +
      '    ELSE CAST(CAST(CS.PITCH_UM / 1000.0 AS NUMERIC(9,3)) AS VARCHAR(20)) || '' mm'' ' +
      '  END AS PITCH_DESC, ' +
      '  CS.REPEAT_MM, ' +
      '  CS.REPEAT_INCH, ' +
      '  CASE ' +
      '    WHEN MC.MACHINE_ID IS NOT NULL THEN ''ASSIGNED'' ' +
      '    ELSE ''AVAILABLE'' ' +
      '  END AS ASSIGNED_STATUS, ' +
      '  (SELECT COUNT(*) FROM DIE D WHERE D.TEETH = CS.TEETH AND D.STATUS_CODE <> ''ARCHIVED'') AS ACTIVE_DIES_COUNT, ' +
      '  COALESCE(CS.NOTES, M.NOTES, '''') AS NOTES ' +
      'FROM MACHINE M ' +
      'CROSS JOIN CYLINDER_SIZE CS ' +
      'LEFT JOIN MACHINE_CYLINDER MC ON (MC.MACHINE_ID = M.ID AND MC.TEETH = CS.TEETH) ' +
      'WHERE M.IS_ACTIVE = 1 AND CS.IS_ACTIVE = 1 ' +
      'ORDER BY M.CODE, CS.TEETH';
    Qry.Open;
    Result := ExecuteReport('cylinder_fleet_matrix.vrt', 'FleetMatrix', Qry, raXlsx, AOutXlsxPath);
  finally
    Qry.Free;
  end;
end;

{ 4. Flatbed Die Tooling Job Bag Card }

procedure TDieVixReportService.PreviewFlatbedToolingCard(const AFlatbedDieID: Integer);
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'SELECT ' +
      '  F.ID, ' +
      '  F.SERIAL_NO, ' +
      '  COALESCE(F.DESCRIPTION, '''') AS DESCRIPTION, ' +
      '  F.CATEGORY, ' +
      '  CASE ' +
      '    WHEN F.CATEGORY = ''ROLL_FORM'' THEN ''Rollform Cutting'' ' +
      '    WHEN F.CATEGORY = ''SHEET_FORM'' THEN ''Sheetform / Booklet Cutting'' ' +
      '    ELSE F.CATEGORY ' +
      '  END AS CATEGORY_DESC, ' +
      '  COALESCE(C.CODE, '''') AS CUSTOMER_CODE, ' +
      '  COALESCE(F.CUSTOMER_NAME, '''') AS CUSTOMER_NAME, ' +
      '  COALESCE(F.CUSTOMER_REF, '''') AS CUSTOMER_REF, ' +
      '  COALESCE(F.INTERNAL_REF, '''') AS INTERNAL_REF, ' +
      '  COALESCE(F.SUPPLIER_REF, '''') AS SUPPLIER_REF, ' +
      '  F.AROUND_SIZE_MM, ' +
      '  F.ACROSS_SIZE_MM, ' +
      '  F.AROUND_UPS, ' +
      '  F.ACROSS_UPS, ' +
      '  (F.AROUND_UPS * F.ACROSS_UPS) AS TOTAL_UPS, ' +
      '  F.AROUND_GAP_MM, ' +
      '  F.ACROSS_GAP_MM, ' +
      '  F.CORNER_RADIUS_MM, ' +
      '  F.SHAPE, ' +
      '  F.PLATE_WIDTH_MM, ' +
      '  F.PLATE_LENGTH_MM, ' +
      '  F.MAX_FEED_STROKE_MM, ' +
      '  F.TOTAL_CUT_AROUND_MM, ' +
      '  F.TOTAL_CUT_ACROSS_MM, ' +
      '  F.CAN_ROTATE, ' +
      '  F.ROTATION_SUPPORT, ' +
      '  CASE ' +
      '    WHEN F.CAN_ROTATE = 1 THEN ''BI-DIRECTIONAL (90'#176' Rotation Allowed)'' ' +
      '    ELSE ''FIXED DIRECTION (Single Orientation Only)'' ' +
      '  END AS ROTATION_BADGE, ' +
      '  COALESCE(F.STORAGE_LOCATION, '''') AS STORAGE_LOCATION, ' +
      '  COALESCE(F.STORAGE_RACK, '''') AS STORAGE_RACK, ' +
      '  COALESCE(F.STORAGE_SHELF, '''') AS STORAGE_SHELF, ' +
      '  COALESCE(F.STORAGE_BIN, '''') AS STORAGE_BIN, ' +
      '  F.STATUS_CODE, ' +
      '  COALESCE(F.STATUS_NAME, '''') AS STATUS_NAME, ' +
      '  COALESCE(M.CODE, '''') AS MEDIA_CODE, ' +
      '  COALESCE(F.MEDIA_NAME, '''') AS MEDIA_NAME, ' +
      '  COALESCE(M.FACE_MATERIAL, '''') AS FACE_MATERIAL, ' +
      '  COALESCE(M.LINER_MATERIAL, '''') AS LINER_MATERIAL, ' +
      '  COALESCE(M.ADHESIVE_TYPE, '''') AS ADHESIVE_TYPE, ' +
      '  COALESCE(M.TOTAL_CALIPER_UM, 0) AS TOTAL_CALIPER_UM, ' +
      '  COALESCE(F.DIE_MAKER, '''') AS DIE_MAKER, ' +
      '  COALESCE(F.TOTAL_IMPRESSIONS, 0) AS TOTAL_IMPRESSIONS, ' +
      '  COALESCE(F.NOTES, '''') AS NOTES, ' +
      '  COALESCE(F.CREATED_BY, '''') AS CREATED_BY, ' +
      '  CAST(F.CREATED_AT AS VARCHAR(25)) AS CREATED_AT ' +
      'FROM V_FLATBED_DIE_CATALOG F ' +
      'LEFT JOIN CUSTOMER C ON F.CUSTOMER_ID = C.ID ' +
      'LEFT JOIN MEDIA M ON F.MEDIA_ID = M.ID ' +
      'WHERE F.ID = :ID';
    Qry.ParamByName('ID').AsInteger := AFlatbedDieID;
    Qry.Open;
    if Qry.IsEmpty then
      raise Exception.CreateFmt('Flatbed die tooling record with ID %d not found.', [AFlatbedDieID]);

    ExecuteReport('flatbed_tooling_card.vrt', 'DieData', Qry, raPreview);
  finally
    Qry.Free;
  end;
end;

function TDieVixReportService.ExportFlatbedToolingCardPdf(const AFlatbedDieID: Integer; const AOutPdfPath: string): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'SELECT ' +
      '  F.ID, ' +
      '  F.SERIAL_NO, ' +
      '  COALESCE(F.DESCRIPTION, '''') AS DESCRIPTION, ' +
      '  F.CATEGORY, ' +
      '  CASE ' +
      '    WHEN F.CATEGORY = ''ROLL_FORM'' THEN ''Rollform Cutting'' ' +
      '    WHEN F.CATEGORY = ''SHEET_FORM'' THEN ''Sheetform / Booklet Cutting'' ' +
      '    ELSE F.CATEGORY ' +
      '  END AS CATEGORY_DESC, ' +
      '  COALESCE(C.CODE, '''') AS CUSTOMER_CODE, ' +
      '  COALESCE(F.CUSTOMER_NAME, '''') AS CUSTOMER_NAME, ' +
      '  COALESCE(F.CUSTOMER_REF, '''') AS CUSTOMER_REF, ' +
      '  COALESCE(F.INTERNAL_REF, '''') AS INTERNAL_REF, ' +
      '  COALESCE(F.SUPPLIER_REF, '''') AS SUPPLIER_REF, ' +
      '  F.AROUND_SIZE_MM, ' +
      '  F.ACROSS_SIZE_MM, ' +
      '  F.AROUND_UPS, ' +
      '  F.ACROSS_UPS, ' +
      '  (F.AROUND_UPS * F.ACROSS_UPS) AS TOTAL_UPS, ' +
      '  F.AROUND_GAP_MM, ' +
      '  F.ACROSS_GAP_MM, ' +
      '  F.CORNER_RADIUS_MM, ' +
      '  F.SHAPE, ' +
      '  F.PLATE_WIDTH_MM, ' +
      '  F.PLATE_LENGTH_MM, ' +
      '  F.MAX_FEED_STROKE_MM, ' +
      '  F.TOTAL_CUT_AROUND_MM, ' +
      '  F.TOTAL_CUT_ACROSS_MM, ' +
      '  F.CAN_ROTATE, ' +
      '  F.ROTATION_SUPPORT, ' +
      '  CASE ' +
      '    WHEN F.CAN_ROTATE = 1 THEN ''BI-DIRECTIONAL (90'#176' Rotation Allowed)'' ' +
      '    ELSE ''FIXED DIRECTION (Single Orientation Only)'' ' +
      '  END AS ROTATION_BADGE, ' +
      '  COALESCE(F.STORAGE_LOCATION, '''') AS STORAGE_LOCATION, ' +
      '  COALESCE(F.STORAGE_RACK, '''') AS STORAGE_RACK, ' +
      '  COALESCE(F.STORAGE_SHELF, '''') AS STORAGE_SHELF, ' +
      '  COALESCE(F.STORAGE_BIN, '''') AS STORAGE_BIN, ' +
      '  F.STATUS_CODE, ' +
      '  COALESCE(F.STATUS_NAME, '''') AS STATUS_NAME, ' +
      '  COALESCE(M.CODE, '''') AS MEDIA_CODE, ' +
      '  COALESCE(F.MEDIA_NAME, '''') AS MEDIA_NAME, ' +
      '  COALESCE(M.FACE_MATERIAL, '''') AS FACE_MATERIAL, ' +
      '  COALESCE(M.LINER_MATERIAL, '''') AS LINER_MATERIAL, ' +
      '  COALESCE(M.ADHESIVE_TYPE, '''') AS ADHESIVE_TYPE, ' +
      '  COALESCE(M.TOTAL_CALIPER_UM, 0) AS TOTAL_CALIPER_UM, ' +
      '  COALESCE(F.DIE_MAKER, '''') AS DIE_MAKER, ' +
      '  COALESCE(F.TOTAL_IMPRESSIONS, 0) AS TOTAL_IMPRESSIONS, ' +
      '  COALESCE(F.NOTES, '''') AS NOTES, ' +
      '  COALESCE(F.CREATED_BY, '''') AS CREATED_BY, ' +
      '  CAST(F.CREATED_AT AS VARCHAR(25)) AS CREATED_AT ' +
      'FROM V_FLATBED_DIE_CATALOG F ' +
      'LEFT JOIN CUSTOMER C ON F.CUSTOMER_ID = C.ID ' +
      'LEFT JOIN MEDIA M ON F.MEDIA_ID = M.ID ' +
      'WHERE F.ID = :ID';
    Qry.ParamByName('ID').AsInteger := AFlatbedDieID;
    Qry.Open;
    if Qry.IsEmpty then
      raise Exception.CreateFmt('Flatbed die tooling record with ID %d not found.', [AFlatbedDieID]);

    Result := ExecuteReport('flatbed_tooling_card.vrt', 'DieData', Qry, raVectorPdf, AOutPdfPath);
  finally
    Qry.Free;
  end;
end;

{ 5. Flatbed Die Master Register Catalog }

procedure TDieVixReportService.BuildFlatbedCatalogQuery(
  const AQry: TFDQuery;
  const AFilter: TFlatbedDieSearchFilter;
  const AParams: TStrings
);
var
  Sql: string;
  TotDies, RollDies, SheetDies, BiDirDies: Integer;
begin
  Sql :=
    'SELECT ' +
    '  F.ID, ' +
    '  F.SERIAL_NO, ' +
    '  F.CATEGORY, ' +
    '  CASE ' +
    '    WHEN F.CATEGORY = ''ROLL_FORM'' THEN ''Rollform'' ' +
    '    WHEN F.CATEGORY = ''SHEET_FORM'' THEN ''Sheetform'' ' +
    '    ELSE F.CATEGORY ' +
    '  END AS CATEGORY_NAME, ' +
    '  COALESCE(C.CODE, '''') AS CUSTOMER_CODE, ' +
    '  COALESCE(F.CUSTOMER_NAME, '''') AS CUSTOMER_NAME, ' +
    '  F.AROUND_SIZE_MM, ' +
    '  F.ACROSS_SIZE_MM, ' +
    '  CAST(CAST(F.AROUND_SIZE_MM AS NUMERIC(9,2)) AS VARCHAR(10)) || '' x '' || CAST(CAST(F.ACROSS_SIZE_MM AS NUMERIC(9,2)) AS VARCHAR(10)) AS CAVITY_TEXT, ' +
    '  F.AROUND_UPS, ' +
    '  F.ACROSS_UPS, ' +
    '  (F.AROUND_UPS * F.ACROSS_UPS) AS TOTAL_UPS, ' +
    '  CAST(F.AROUND_UPS AS VARCHAR(10)) || '' x '' || CAST(F.ACROSS_UPS AS VARCHAR(10)) || '' ('' || CAST((F.AROUND_UPS * F.ACROSS_UPS) AS VARCHAR(10)) || '')'' AS UPS_TEXT, ' +
    '  F.TOTAL_CUT_AROUND_MM, ' +
    '  F.TOTAL_CUT_ACROSS_MM, ' +
    '  CAST(CAST(F.TOTAL_CUT_AROUND_MM AS NUMERIC(9,2)) AS VARCHAR(10)) || '' x '' || CAST(CAST(F.TOTAL_CUT_ACROSS_MM AS NUMERIC(9,2)) AS VARCHAR(10)) AS CUT_FOOTPRINT_TEXT, ' +
    '  F.PLATE_WIDTH_MM, ' +
    '  F.PLATE_LENGTH_MM, ' +
    '  CAST(CAST(F.PLATE_WIDTH_MM AS NUMERIC(9,2)) AS VARCHAR(10)) || '' x '' || CAST(CAST(F.PLATE_LENGTH_MM AS NUMERIC(9,2)) AS VARCHAR(10)) AS PLATE_SIZE_TEXT, ' +
    '  F.CAN_ROTATE, ' +
    '  CASE ' +
    '    WHEN F.CAN_ROTATE = 1 THEN ''Bi-Directional'' ' +
    '    ELSE ''Fixed'' ' +
    '  END AS ROTATION_TEXT, ' +
    '  F.ROTATION_SUPPORT, ' +
    '  COALESCE(F.STATUS_NAME, '''') AS STATUS_NAME, ' +
    '  F.STATUS_CODE, ' +
    '  COALESCE(F.STORAGE_LOCATION, '''') AS STORAGE_LOCATION ' +
    'FROM V_FLATBED_DIE_CATALOG F ' +
    'LEFT JOIN CUSTOMER C ON F.CUSTOMER_ID = C.ID ' +
    'WHERE (1 = 1) ';

  if Trim(AFilter.SearchText) <> '' then
  begin
    Sql := Sql +
      ' AND (UPPER(F.SERIAL_NO) LIKE :ST ' +
      '  OR UPPER(F.DESCRIPTION) LIKE :ST ' +
      '  OR UPPER(F.CUSTOMER_REF) LIKE :ST ' +
      '  OR UPPER(F.CUSTOMER_NAME) LIKE :ST ' +
      '  OR UPPER(F.INTERNAL_REF) LIKE :ST) ';
  end;

  if Trim(AFilter.Category) <> '' then
    Sql := Sql + ' AND (F.CATEGORY = :CAT) ';

  if AFilter.CustomerID > 0 then
    Sql := Sql + ' AND (F.CUSTOMER_ID = :CUSTID) ';

  if AFilter.MediaID > 0 then
    Sql := Sql + ' AND (F.MEDIA_ID = :MEDIAID) ';

  if Trim(AFilter.StatusCode) <> '' then
    Sql := Sql + ' AND (F.STATUS_CODE = :STATUS) ';

  if Trim(AFilter.Shape) <> '' then
    Sql := Sql + ' AND (F.SHAPE = :SHAPE) ';

  if Trim(AFilter.StorageLocation) <> '' then
  begin
    Sql := Sql +
      ' AND (UPPER(F.STORAGE_LOCATION) LIKE :LOC ' +
      '  OR UPPER(F.STORAGE_RACK) LIKE :LOC ' +
      '  OR UPPER(F.STORAGE_SHELF) LIKE :LOC ' +
      '  OR UPPER(F.STORAGE_BIN) LIKE :LOC) ';
  end;

  if AFilter.ActiveOnly then
    Sql := Sql + ' AND (F.STATUS_CODE IN (''ACTIVE'', ''AVAILABLE'', ''IN_USE'')) '
  else if Trim(AFilter.StatusCode) <> '' then
    Sql := Sql + ' AND (F.STATUS_CODE = :STATUS) '
  else if not AFilter.IncludeArchived then
    Sql := Sql + ' AND (F.STATUS_CODE <> ''ARCHIVED'') ';

  if AFilter.MatchDimensions and (AFilter.TargetAroundMm > 0) and (AFilter.TargetAcrossMm > 0) then
  begin
    if AFilter.AllowRotation then
    begin
      Sql := Sql +
        ' AND ((ABS(F.AROUND_SIZE_MM - :TAROUND) <= :TOL AND ABS(F.ACROSS_SIZE_MM - :TACROSS) <= :TOL) ' +
        '   OR (F.CAN_ROTATE = 1 AND ABS(F.AROUND_SIZE_MM - :TACROSS) <= :TOL AND ABS(F.ACROSS_SIZE_MM - :TAROUND) <= :TOL)) ';
    end
    else
    begin
      Sql := Sql +
        ' AND (ABS(F.AROUND_SIZE_MM - :TAROUND) <= :TOL AND ABS(F.ACROSS_SIZE_MM - :TACROSS) <= :TOL) ';
    end;
  end;

  Sql := Sql + ' ORDER BY F.SERIAL_NO ASC';

  AQry.SQL.Text := Sql;

  if Trim(AFilter.SearchText) <> '' then
    AQry.ParamByName('ST').AsString := '%' + UpperCase(Trim(AFilter.SearchText)) + '%';
  if Trim(AFilter.Category) <> '' then
    AQry.ParamByName('CAT').AsString := Trim(AFilter.Category);
  if AFilter.CustomerID > 0 then
    AQry.ParamByName('CUSTID').AsInteger := AFilter.CustomerID;
  if AFilter.MediaID > 0 then
    AQry.ParamByName('MEDIAID').AsInteger := AFilter.MediaID;
  if Trim(AFilter.StatusCode) <> '' then
    AQry.ParamByName('STATUS').AsString := Trim(AFilter.StatusCode);
  if Trim(AFilter.Shape) <> '' then
    AQry.ParamByName('SHAPE').AsString := Trim(AFilter.Shape);
  if Trim(AFilter.StorageLocation) <> '' then
    AQry.ParamByName('LOC').AsString := '%' + UpperCase(Trim(AFilter.StorageLocation)) + '%';

  if AFilter.MatchDimensions and (AFilter.TargetAroundMm > 0) and (AFilter.TargetAcrossMm > 0) then
  begin
    AQry.ParamByName('TAROUND').AsFloat := AFilter.TargetAroundMm;
    AQry.ParamByName('TACROSS').AsFloat := AFilter.TargetAcrossMm;
    if AFilter.ToleranceMm > 0 then
      AQry.ParamByName('TOL').AsFloat := AFilter.ToleranceMm
    else
      AQry.ParamByName('TOL').AsFloat := 0.500;
  end;

  AQry.Open;

  TotDies := 0;
  RollDies := 0;
  SheetDies := 0;
  BiDirDies := 0;

  AQry.First;
  while not AQry.Eof do
  begin
    Inc(TotDies);
    if SameText(AQry.FieldByName('CATEGORY').AsString, 'ROLL_FORM') then
      Inc(RollDies)
    else if SameText(AQry.FieldByName('CATEGORY').AsString, 'SHEET_FORM') then
      Inc(SheetDies);

    if AQry.FieldByName('CAN_ROTATE').AsInteger = 1 then
      Inc(BiDirDies);

    AQry.Next;
  end;
  AQry.First;

  if Assigned(AParams) then
  begin
    AParams.Values['TotalCount'] := IntToStr(TotDies);
    AParams.Values['RollCount'] := IntToStr(RollDies);
    AParams.Values['SheetCount'] := IntToStr(SheetDies);
    AParams.Values['BiDirectionalCount'] := IntToStr(BiDirDies);
  end;
end;

procedure TDieVixReportService.PreviewFlatbedRegisterCatalog(const AFilter: TFlatbedDieSearchFilter);
var
  Qry: TFDQuery;
  Params: TStringList;
begin
  Qry := CreateQuery;
  Params := TStringList.Create;
  try
    BuildFlatbedCatalogQuery(Qry, AFilter, Params);
    ExecuteReport('flatbed_register_catalog.vrt', 'DieList', Qry, raPreview, '', Params);
  finally
    Params.Free;
    Qry.Free;
  end;
end;

function TDieVixReportService.ExportFlatbedRegisterCatalogPdf(const AFilter: TFlatbedDieSearchFilter; const AOutPdfPath: string): Boolean;
var
  Qry: TFDQuery;
  Params: TStringList;
begin
  Qry := CreateQuery;
  Params := TStringList.Create;
  try
    BuildFlatbedCatalogQuery(Qry, AFilter, Params);
    Result := ExecuteReport('flatbed_register_catalog.vrt', 'DieList', Qry, raVectorPdf, AOutPdfPath, Params);
  finally
    Params.Free;
    Qry.Free;
  end;
end;

function TDieVixReportService.ExportFlatbedRegisterCatalogXlsx(const AFilter: TFlatbedDieSearchFilter; const AOutXlsxPath: string): Boolean;
var
  Qry: TFDQuery;
  Params: TStringList;
begin
  Qry := CreateQuery;
  Params := TStringList.Create;
  try
    BuildFlatbedCatalogQuery(Qry, AFilter, Params);
    Result := ExecuteReport('flatbed_register_catalog.vrt', 'DieList', Qry, raXlsx, AOutXlsxPath, Params);
  finally
    Params.Free;
    Qry.Free;
  end;
end;

end.
