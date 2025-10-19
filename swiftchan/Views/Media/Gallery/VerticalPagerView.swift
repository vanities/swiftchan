//
//  VerticalPagerView.swift
//  swiftchan
//
//  Created on 5/16/24.
//

import SwiftUI
import UIKit

struct VerticalPagerView<Content: View>: UIViewControllerRepresentable {
    @Binding var selection: Int
    var pageCount: Int
    var canScroll: Bool
    var onPageChanged: ((Int) -> Void)?
    var onDragChanged: ((CGFloat) -> Void)?
    var onDragEnded: (() -> Void)?
    var onScrollViewCaptured: ((UIScrollView) -> Void)?
    var content: (Int) -> Content

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let controller = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .vertical,
            options: nil
        )
        controller.delegate = context.coordinator
        controller.dataSource = context.coordinator
        context.coordinator.update(parent: self, controller: controller)

        if let initial = context.coordinator.controller(for: selection) {
            controller.setViewControllers([initial], direction: .forward, animated: false)
            context.coordinator.currentIndex = selection
        }

        context.coordinator.attachScrollView(to: controller)

        return controller
    }

    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        context.coordinator.update(parent: self, controller: uiViewController)

        let clampedSelection = min(max(selection, 0), max(pageCount - 1, 0))
        guard context.coordinator.currentIndex != clampedSelection,
              let target = context.coordinator.controller(for: clampedSelection) else { return }

        let direction: UIPageViewController.NavigationDirection = clampedSelection >= context.coordinator.currentIndex ? .forward : .reverse
        context.coordinator.isSettingViewController = true
        uiViewController.setViewControllers([target], direction: direction, animated: abs(clampedSelection - context.coordinator.currentIndex) == 1) { _ in
            context.coordinator.isSettingViewController = false
            context.coordinator.currentIndex = clampedSelection
        }
    }
}

extension VerticalPagerView {
    final class Coordinator: NSObject, UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIScrollViewDelegate {
        private var parent: VerticalPagerView
        private var controllers: [Int: IndexedHostingController<Content>] = [:]
        weak var pageViewController: UIPageViewController?
        weak var scrollView: UIScrollView?
        var currentIndex: Int = 0
        var isSettingViewController = false

        init(parent: VerticalPagerView) {
            self.parent = parent
            super.init()
        }

        func update(parent: VerticalPagerView, controller: UIPageViewController) {
            self.parent = parent
            self.pageViewController = controller

            pruneControllers()
            attachScrollView(to: controller)
            updateScrollConfiguration()
        }

        fileprivate func controller(for index: Int) -> IndexedHostingController<Content>? {
            guard parent.pageCount > 0,
                  (0..<parent.pageCount).contains(index) else { return nil }

            if let cached = controllers[index] {
                return cached
            }

            let hosting = IndexedHostingController(
                index: index,
                rootView: IndexedContent(index: index, builder: parent.content)
            )
            controllers[index] = hosting
            return hosting
        }

        private func pruneControllers() {
            let validRange = 0..<parent.pageCount
            controllers = controllers.filter { validRange.contains($0.key) }
        }

        func attachScrollView(to controller: UIPageViewController) {
            guard scrollView == nil else { return }
            guard let scrollView = controller.view.subviews.compactMap({ $0 as? UIScrollView }).first else { return }
            self.scrollView = scrollView
            scrollView.delegate = self
            scrollView.showsVerticalScrollIndicator = false
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.alwaysBounceVertical = true
            scrollView.alwaysBounceHorizontal = false
            scrollView.bounces = true
            scrollView.clipsToBounds = false
            updateScrollConfiguration()
            parent.onScrollViewCaptured?(scrollView)
        }

        private func updateScrollConfiguration() {
            scrollView?.isScrollEnabled = parent.canScroll
            scrollView?.panGestureRecognizer.isEnabled = parent.canScroll
        }

        // MARK: - UIPageViewControllerDataSource
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let hosting = viewController as? IndexedHostingController<Content> else { return nil }
            return controller(for: hosting.index - 1)
        }

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let hosting = viewController as? IndexedHostingController<Content> else { return nil }
            return controller(for: hosting.index + 1)
        }

        // MARK: - UIPageViewControllerDelegate
        func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
            guard let hosting = pendingViewControllers.first as? IndexedHostingController<Content> else { return }
            currentIndex = hosting.index
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            guard completed,
                  let hosting = pageViewController.viewControllers?.first as? IndexedHostingController<Content> else { return }
            currentIndex = hosting.index
            parent.selection = hosting.index
            parent.onPageChanged?(hosting.index)
        }

        // MARK: - UIScrollViewDelegate
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard parent.canScroll else { return }
            let baseline = scrollView.bounds.height
            let translation = baseline - scrollView.contentOffset.y
            parent.onDragChanged?(translation)
        }

        func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
            guard parent.canScroll else { return }
            parent.onDragChanged?(0)
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            guard parent.canScroll else { return }
            if !decelerate {
                parent.onDragChanged?(.zero)
                parent.onDragEnded?()
            }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            guard parent.canScroll else { return }
            parent.onDragChanged?(.zero)
            parent.onDragEnded?()
        }
    }
}

// MARK: - Supporting Types
private struct IndexedContent<Content: View>: View {
    let index: Int
    let builder: (Int) -> Content

    var body: some View {
        builder(index)
    }
}

fileprivate final class IndexedHostingController<Content: View>: UIHostingController<IndexedContent<Content>> {
    let index: Int

    init(index: Int, rootView: IndexedContent<Content>) {
        self.index = index
        super.init(rootView: rootView)
        view.backgroundColor = .clear
    }

    @MainActor @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
