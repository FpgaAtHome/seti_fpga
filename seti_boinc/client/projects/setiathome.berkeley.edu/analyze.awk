/EXE_TIME/ {
	counts[$5] = counts[$5] + 1;
	exe_time[$5] = exe_time[$5] + $8;
}

END {
	print "Histogram"
	for (val in counts)
		print val, counts[val];
	print "Total Execution time"
	for (val in exe_time)
		print val, exe_time[val];
}
