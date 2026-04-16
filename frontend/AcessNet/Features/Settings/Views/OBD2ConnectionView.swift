//
//  OBD2ConnectionView.swift
//  AcessNet
//
//  Vista de conexión a dongle OBD-II Bluetooth.
//  Muestra: estado BLE, datos live (RPM/velocidad/MAF/fuel rate), instant km/L.
//

import SwiftUI

struct OBD2ConnectionView: View {
    @StateObject private var obd = OBD2Service.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header

                    statusCard

                    if obd.state.isConnected {
                        liveDashboard
                        rawResponses
                    } else {
                        instructions
                    }

                    controls
                }
                .padding()
            }
            .navigationTitle("OBD-II")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "car.fill")
                .font(.system(size: 52))
                .foregroundStyle(LinearGradient(
                    colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom
                ))
            Text("Conecta tu dongle")
                .font(.title3.bold())
            Text("Compatible con ELM327 BLE: Vgate iCar Pro, OBDLink MX+, Kiwi 3, vLinker MC+.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var statusCard: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
            Text(obd.state.label)
                .font(.callout.weight(.semibold))
            Spacer()
            if case .scanning = obd.state {
                ProgressView()
            }
        }
        .padding(12)
        .background(statusColor.opacity(0.12))
        .cornerRadius(10)
    }

    private var statusColor: Color {
        switch obd.state {
        case .connected: return .green
        case .scanning, .connecting: return .blue
        case .failed: return .red
        case .disconnected: return .secondary
        }
    }

    private var liveDashboard: some View {
        VStack(spacing: 12) {
            // Gran número central = instant km/L o fuel rate
            VStack {
                if let kmL = obd.liveData.instantKmPerL {
                    Text(String(format: "%.1f", kmL))
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("km/L (instantáneo)")
                        .font(.caption).foregroundColor(.secondary)
                } else {
                    Text(String(format: "%.2f", obd.liveData.computedFuelRateLh))
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("L/hr (consumo actual)")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(LinearGradient(
                colors: [.blue.opacity(0.15), .cyan.opacity(0.1)],
                startPoint: .top, endPoint: .bottom
            ))
            .cornerRadius(14)

            // Grid de métricas
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                metric(icon: "gauge", label: "Velocidad", value: "\(obd.liveData.speedKmh)", unit: "km/h")
                metric(icon: "speedometer", label: "RPM", value: "\(obd.liveData.rpm)", unit: "")
                metric(icon: "wind", label: "MAF", value: String(format: "%.1f", obd.liveData.mafGs), unit: "g/s")
                metric(icon: "gearshape.fill", label: "Carga motor", value: String(format: "%.0f", obd.liveData.engineLoadPct), unit: "%")
                metric(icon: "thermometer.high", label: "Temp motor", value: "\(obd.liveData.engineTempC)", unit: "°C")
                metric(icon: "hand.raised.fill", label: "Acelerador", value: String(format: "%.0f", obd.liveData.throttlePct), unit: "%")
            }
        }
    }

    private func metric(icon: String, label: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(value)
                .font(.title3.bold())
                .monospacedDigit()
            Text("\(label) \(unit)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(10)
    }

    private var rawResponses: some View {
        DisclosureGroup("Log BLE") {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(obd.recentResponses.suffix(10), id: \.self) { r in
                    Text(r)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.caption)
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cómo conectar")
                .font(.headline)
            Label("Enchufa el dongle en el puerto OBD-II (abajo del volante)", systemImage: "1.circle.fill")
            Label("Enciende el auto (ignición en ON, no necesita arrancar)", systemImage: "2.circle.fill")
            Label("Permite Bluetooth a AirWay en Ajustes → AirWay → Bluetooth", systemImage: "3.circle.fill")
            Label("Toca 'Buscar dongles' abajo", systemImage: "4.circle.fill")
        }
        .font(.callout)
        .padding()
        .background(Color.blue.opacity(0.08))
        .cornerRadius(12)
    }

    private var controls: some View {
        VStack(spacing: 10) {
            if obd.state.isConnected {
                Button(role: .destructive) {
                    obd.disconnect()
                } label: {
                    Label("Desconectar", systemImage: "xmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            } else {
                Button {
                    obd.scan()
                } label: {
                    Label("Buscar dongles", systemImage: "antenna.radiowaves.left.and.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
}
