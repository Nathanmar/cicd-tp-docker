<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;

class HealthController extends Controller
{
    public function __invoke()
    {
        $health = [
            'status' => 'healthy',
            'timestamp' => now()->toIso8601String(),
        ];

        try {
            // Test connexion PostgreSQL
            DB::connection()->getPdo();
            $health['database'] = 'connected';
        } catch (\Exception $e) {
            $health['status'] = 'unhealthy';
            $health['database'] = 'disconnected';
        }

        try {
            // Test connexion Redis
            Redis::connection()->ping();
            $health['cache'] = 'connected';
        } catch (\Exception $e) {
            $health['status'] = 'unhealthy';
            $health['cache'] = 'disconnected';
        }

        $code = $health['status'] === 'healthy' ? 200 : 503;

        return response()->json($health, $code);
    }
}
