--[[
This script is automatically added to the model directory.  Extraction scripts
are used to generate an *.hstp output file that is recognised by HyperStudy.
--]]

HstUtl = require "hst.hstutl"
plpath = require 'pl.path'
plstringx = require 'pl.stringx'
local app = feko.GetApplication()

local function Escape(s)
    local s = plstringx.replace(s," ","_")
    local s = plstringx.replace(s,".","_")
    local s = plstringx.replace(s,"-","_")
    local s = plstringx.replace(s,":","_")
    return s
end

--- Extract trace data from supported graphs.
-- The variables and their HyperStudy-generated values are 
-- processed and used to modify the CADFEKO model.
-- @param file (string) hstoutput file handle that the contents will be written to.
-- @param graphTypeCollection the graphcollectoin to extract the trace data from (currently cartesiangrpahs and polar graphs are supported)
local function extractRawTraceData(file,graphTypeCollection)
    for kGraph,vGraph in pairs(graphTypeCollection) do
            for kTrace,vTrace in pairs(vGraph.Traces) do
                if vTrace.Visible then
                    local labelPreffix = string.format("%s:%s",Escape(vGraph.WindowTitle) ,vTrace.Label)
                    local data = vTrace.Values
                    local dataN = data.RowCount
                    local xTable,yTable = {},{}
                    for k=1, dataN do 
                        xTable[k] = data[k][1]
                        yTable[k] = data[k][2]
                    end
                    if dataN > 1 then
                        HstUtl.StoreScalarList( file, string.format("%s:AXIS",labelPreffix), xTable )
                        HstUtl.StoreScalarList( file, string.format("%s:QUANTITY",labelPreffix), yTable )                                                                               
                    else
                        HstUtl.StoreScalarValue( file,labelPreffix, data[1][2])
                    end
                end
            end
        end
    return file
end

-- Extract annotation data from supported graphs.
-- The variables and their HyperStudy-generated values are 
-- processed and used to modify the CADFEKO model.
-- @param file (string) hstoutput file handle that the contents will be written to.
-- @param graphTypeCollection the graphcollectoin to extract the trace data from (currently cartesiangrpahs and polar graphs are supported)
local function extractAnnotationData(file,graphTypeCollection)
    for kGraph,vGraph in pairs(graphTypeCollection) do
        for kAnnotation,vAnnotation in pairs(vGraph.Annotations) do
            local propertiesAnnot = vAnnotation:GetProperties()
            local valuesAnnot = vAnnotation:GetValues()           
            if propertiesAnnot.SinglePointAnnotationType ~= nil then
                local labelPreffix = string.format("%s:%s:%s",Escape(vGraph.WindowTitle) ,propertiesAnnot.Trace.Label,propertiesAnnot.SinglePointAnnotationType)
                HstUtl.StoreScalarValue( file,string.format("%s:QUANTITY",labelPreffix),(valuesAnnot.axis_value_dependent * valuesAnnot.axis_unit_scale_dependent ))
                HstUtl.StoreScalarValue( file,string.format("%s:AXIS",labelPreffix),(valuesAnnot.axis_value_independent * valuesAnnot.axis_unit_scale_independent ))
            end
            if propertiesAnnot.BandwidthType ~= nil then           
                local labelPreffix = string.format("%s:%s:%s_(%s)_dB_bandwidth",Escape(vGraph.WindowTitle) ,propertiesAnnot.Trace.Label,propertiesAnnot.BandwidthType,tostring(math.floor(propertiesAnnot.BandwidthLevel)))
                HstUtl.StoreScalarValue( file,labelPreffix,tostring(valuesAnnot.dx))
            end
            if propertiesAnnot.BeamwidthType ~=  nil then             
                local labelPreffix = string.format("%s:%s:%s",Escape(vGraph.WindowTitle) ,propertiesAnnot.Trace.Label,propertiesAnnot.BeamwidthType)
                HstUtl.StoreScalarValue( file,labelPreffix,tostring(valuesAnnot.dx))             
            end  
            if propertiesAnnot.WidthType ~=  nil then
                local labelPreffix = string.format("%s:%s:%s",Escape(vGraph.WindowTitle) ,propertiesAnnot.Trace.Label,propertiesAnnot.WidthType)
                HstUtl.StoreScalarValue( file,labelPreffix,tostring(valuesAnnot.dy))             
            end  
        end
    end
    return file
end    
--- This function writes the trace data to the hst output file to enable the user to easily manipulate the data on HyperStudy
local function writeExtractScriptWithTraceData()
    local path = app.Models[1]:GetPath()
    local modelname = app.Models[1].Label
    local model = app.Models[1]
    local config = model.Configurations[1]
    local configCount = model.Configurations.Count
    local pfsPath = plpath.join(path,string.format("%s.pfs",plpath.splitext(modelname)))
    local validPFS = HstUtl.OpenPFSession(pfsPath)
    local file = HstUtl.NewOutputFile()  
    -- test entry in output file with total number of confugurations uncomment if required
    -- HstUtl.StoreScalarValue( file, "num_configurations", configCount )
    if validPFS then  
        file = extractRawTraceData(file,app.CartesianGraphs)
        file = extractRawTraceData(file,app.PolarGraphs)  
        file = extractAnnotationData(file,app.CartesianGraphs)
        file = extractAnnotationData(file,app.PolarGraphs)
    end 
    HstUtl.WriteFile( file )
end
   
writeExtractScriptWithTraceData()
