<?php
include(dirname(__FILE__)."/../db/sqlitedb.php");
include(dirname(__FILE__)."/config.php");

$db = get_db_handle();
$db->beginTransaction();
$projectStatus = array();

foreach($PROJECTS as $project => $label) {
	$comm = "SELECT * FROM status WHERE name = '".$project."' ORDER BY tstart DESC LIMIT 10;";
	$result = $db->prepare($comm);
	$result->execute();
	$rows = $result->fetchAll(PDO::FETCH_ASSOC);

	# convert time and add key
	for($i=0; $i<count($rows); $i++) {
		$rows[$i]["tstart"] = date('Y-m-d H:i:s', $rows[$i]["tstart"]);
		$rows[$i]["tend"] = date('Y-m-d H:i:s', $rows[$i]["tend"]);
	}

	$retVal["label"] = $label;
	$retVal["rows"] = $rows;
	$projectStatus[$project] = $retVal;
}

$db->commit();
echo json_encode($projectStatus);
?>
