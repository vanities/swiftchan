//
//  PullToRefresh.swift
//  swiftchan
//
//  Created by vanities on 11/23/20.
//

import SwiftUI
import Introspect

import SwiftUI
import Introspect

private struct PullToRefresh: UIViewRepresentable {

    @Binding var isRefreshing: Bool
    let onRefresh: () -> Void

    public init(
        isRefreshing: Binding<Bool>,
        onRefresh: @escaping () -> Void
    ) {
        self._isRefreshing = isRefreshing
        self.onRefresh = onRefresh
    }

    public class Coordinator {
        let onRefresh: () -> Void
        let isRefreshing: Binding<Bool>

        init(
            onRefresh: @escaping () -> Void,
            isRefreshing: Binding<Bool>
        ) {
            self.onRefresh = onRefresh
            self.isRefreshing = isRefreshing
        }

        @objc
        func onValueChanged() {
            isRefreshing.wrappedValue = true
            onRefresh()
        }
    }

    public func makeUIView(context: UIViewRepresentableContext<PullToRefresh>) -> UIView {
        let view = UIView(frame: .zero)
        view.isHidden = true
        view.isUserInteractionEnabled = false
        return view
    }

    // MARK: - Scroll View -
    private func scrollView(entry: UIView) -> UIScrollView? {

        if let scrollView = Introspect.findAncestor(
            ofType: UIScrollView.self, from: entry
        ) {

            return scrollView
        }

        guard let viewHost = Introspect.findViewHost(from: entry) else {
            return nil
        }

        return Introspect.previousSibling(
            containing: UIScrollView.self, from: viewHost
        )

    }

    // MARK: - Update UI View
    public func updateUIView(
        _ uiView: UIView,
        context: UIViewRepresentableContext<PullToRefresh>
    ) {

        DispatchQueue.main.async {

            guard let scrollableView = self.scrollView(entry: uiView) else {
                return
            }

            // if the refresh control has already been attached,
            // then update it based on the `isRefreshing` binding
            if let refreshControl = scrollableView.refreshControl {
                if self.isRefreshing {
                    refreshControl.beginRefreshing()
                } else {
                    refreshControl.endRefreshing()
                }
                return  // note the return
            }

            // else, create a new refresh control
            let refreshControl = UIRefreshControl()

            // add a delegate to watch for when the user scrolls
            refreshControl.addTarget(
                context.coordinator,
                action: #selector(Coordinator.onValueChanged),
                for: .valueChanged
            )

            // attach the refresh control to the scrollable view
            scrollableView.refreshControl = refreshControl
        }
    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(
            onRefresh: onRefresh, isRefreshing: $isRefreshing
        )
    }
}

extension View {

    /**
    Attaches a refresh control to the view.
    
    - Parameters:
      - isRefreshing: True if view is currently refreshing,
            else false.
      - onRefresh: A closure that gets called
            when the user pulls down to refresh the view.
            When this happens, `isRefreshing` gets set to true.
            You must set it back to false when new data
            has finished loading, which will dismiss
            the activity indicator.
    */
    public func pullToRefresh(
        isRefreshing: Binding<Bool>,
        onRefresh: @escaping () -> Void
    ) -> some View {

        return overlay(
            PullToRefresh(
                isRefreshing: isRefreshing,
                onRefresh: onRefresh
            )
            .frame(width: 0, height: 0)
        )
    }
}

/*
struct PullToRefresh_Previews: PreviewProvider {
    static var previews: some View {
        PullToRefresh(isShowing: <#Binding<Bool>#>, onRefresh: <#() -> Void#>)
    }
}
 */
