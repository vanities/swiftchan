//
//  Toast.swift
//  swiftchan
//
//  Created on 11/7/21.
//

import SwiftUI

// MARK: - Toast View

struct CustomToastView: View {
    let message: String
    let style: ToastStyle

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: style.iconName)
                .font(.system(size: 44))
                .foregroundStyle(style.iconColor)

            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 140, height: 140)
        .background {
            if #available(iOS 26.0, *) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.clear)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 20))
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .compositingGroup()
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Toast Styles

enum ToastStyle {
    case success
    case error
    case info

    var iconName: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .info:
            return "info.circle.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .success:
            return .green
        case .error:
            return .red
        case .info:
            return .blue
        }
    }
}

// MARK: - Legacy Toast Support (for compatibility)

struct Toast<T>: View {
    let presentingToastResult: Result<T, Error>?

    var message: String {
        switch presentingToastResult {
        case .success:
            return "Success!"
        case .failure(let error):
            return error.localizedDescription
        case .none:
            return "Failed"
        }
    }

    var style: ToastStyle {
        switch presentingToastResult {
        case .success:
            return .success
        case .failure, .none:
            return .error
        }
    }

    var body: some View {
        CustomToastView(message: message, style: style)
    }
}

// MARK: - Legacy ToastUI Compatibility

struct ToastView: View {
    let message: String

    init(_ message: String, content: @escaping () -> Any, background: @escaping () -> Any) {
        self.message = message
    }

    var body: some View {
        CustomToastView(message: message, style: .info)
    }

    func toastViewStyle(_ style: any ToastViewStyleProtocol) -> some View {
        CustomToastView(message: message, style: style.toastStyle)
    }
}

protocol ToastViewStyleProtocol {
    var toastStyle: ToastStyle { get }
}

struct SuccessToastViewStyle: ToastViewStyleProtocol {
    var toastStyle: ToastStyle { .success }
}

struct ErrorToastViewStyle: ToastViewStyleProtocol {
    var toastStyle: ToastStyle { .error }
}

// MARK: - Legacy toast modifier for compatibility

struct ToastViewContentModifier<ToastContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let dismissAfter: TimeInterval
    let toastContent: () -> ToastContent

    @State private var workItem: DispatchWorkItem?

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .center) {
                if isPresented {
                    toastContent()
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                        .onAppear {
                            scheduleAutoDismiss()
                        }
                        .onTapGesture {
                            dismiss()
                        }
                        .zIndex(999)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPresented)
    }

    private func scheduleAutoDismiss() {
        workItem?.cancel()

        let task = DispatchWorkItem {
            dismiss()
        }

        workItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissAfter, execute: task)
    }

    private func dismiss() {
        withAnimation {
            isPresented = false
        }
        workItem?.cancel()
        workItem = nil
    }
}

extension View {
    func toast<Content: View>(
        isPresented: Binding<Bool>,
        dismissAfter: TimeInterval = 2.0,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(ToastViewContentModifier(
            isPresented: isPresented,
            dismissAfter: dismissAfter,
            toastContent: content
        ))
    }
}
