-- CFDP PDU extraction from CF application telemetry
-- CF table ch0 output MID = 0x0FFD (4093), ch1 output MID = 0x08C3 (2243)
create stream cfdp_in as select substring(packet, 12) as pdu from tm_realtime where extract_short(packet, 0) = 4093 or extract_short(packet, 0) = 2243
create stream cfdp_out (gentime TIMESTAMP, entityId long, seqNum int, pdu binary)
-- Route CFDP PDUs using proper CFDP_PDU command definition
insert into tc_realtime select gentime, 'cfdp-service' as origin, seqNum, '/CFDP/CFDP_PDU' as cmdName, pdu as binary from cfdp_out