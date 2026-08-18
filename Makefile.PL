use inc::Module::Install;

RTx     'RT-Extension-LastLogin';
license 'gpl_2';
repository 'https://github.com/NETWAYS/rt-extension-lastlogin';
readme_from 'lib/RT/Extension/LastLogin.pm';

requires_rt '6.0.0';

WriteAll;
