<?php

return [
    'debug' => false,
    'database' => [
        'driver' => 'mysql',
        'host' => getenv('FLARUM_DB_HOST'),
        'port' => getenv('FLARUM_DB_PORT'),
        'database' => getenv('FLARUM_DB_NAME'),
        'username' => getenv('FLARUM_DB_USER'),
        'password' => getenv('FLARUM_DB_PASS'),
        'charset' => 'utf8mb4',
        'collation' => 'utf8mb4_unicode_ci',
        'prefix' => '',
        'strict' => false,
        'engine' => 'InnoDB',
        'prefix_indexes' => true,
    ],
    'url' => getenv('FLARUM_BASE_URL'),
    'paths' => [
        'api' => 'api',
        'admin' => 'admin',
    ],
];