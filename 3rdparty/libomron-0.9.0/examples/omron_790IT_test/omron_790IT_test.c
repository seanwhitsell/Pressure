#include "libomron/omron.h"
#include <stdio.h>
#include <stdlib.h>		/* atoi */

int main(int argc, char** argv)
{
	omron_device* test;
	int ret;
	int i;
	int data_count;
	unsigned char str[30];
	int bank = 0;

	if (argc > 1)
		bank = atoi(argv[1]);

	test = omron_create();
	
	ret = omron_get_count(test, OMRON_VID, OMRON_PID);

	if(!ret)
	{
		printf("No omron 790ITs connected!\n");
		return 1;
	}
	printf("Found %d omron 790ITs\n", ret);

	ret = omron_open(test, OMRON_VID, OMRON_PID, 0);
	if(ret < 0)
	{
		printf("Cannot open omron 790IT!\n");
		return 1;
	}
	printf("Opened omron 790IT\n", ret);

	ret = omron_get_device_version(test, str);
	if(ret < 0)
	{
		printf("Cannot get device version!\n");
	}
	else
	{
		printf("Device serial: %s\n", str);
	}

	ret = omron_get_bp_profile(test, str);
	if(ret < 0)
	{
		printf("Cannot get device prf!\n");
	}
	else
	{
		printf("Device version: %s\n", str);
	}

	data_count = omron_get_daily_data_count(test, bank);
	printf("AJR data count: %d\n", data_count);
	if(data_count < 0)
	{
		printf("Cannot get device prf!\n");
	}

	for(i = data_count - 1; i >= 0; --i)
	{
		omron_bp_day_info r = omron_get_daily_bp_data(test, bank, i);
		if(!r.present)
		{
			i = i + 1;
			continue;
		}
		printf("%.2d/%.2d/20%.2d %.2d:%.2d:%.2d SYS: %3d DIA: %3d PULSE: %3d\n", r.day, r.month, r.year, r.hour, r.minute, r.second, r.sys, r.dia, r.pulse);
	}

	printf("Weekly info:\n");
	for(i = 0; i < 9; i++) {
	  	omron_bp_week_info w;

		w = omron_get_weekly_bp_data(test, bank, i, 0);
		if (w.present && w.dia != 0)
			printf("Morning[%d %02d/%02d/20%02d] = sys:%d dia:%d pulse:%d.\n", i, w.day, w.month, w.year, w.sys, w.dia, w.pulse);

		w = omron_get_weekly_bp_data(test, bank, i, 1);
		if (w.present && w.dia != 0)
			printf("Evening[%d %02d/%02d/20%02d] = sys:%d dia:%d pulse:%d.\n", i, w.day, w.month, w.year, w.sys, w.dia, w.pulse);
	}



	ret = omron_close(test);
	if(ret < 0)
	{
		printf("Cannot close omron 790IT!\n");
		return 1;
	}
	return 0;
}
