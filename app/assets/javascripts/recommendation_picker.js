(() => {
  // TOP画面にある候補ピッカーを初期化する。Turbo遷移での二重登録も防ぐ。
  const initializeRecommendationPickers = () => {
    // 達成後のメッセージがある場合は、自動でダイアログを表示する。
    document.querySelectorAll("[data-completion-dialog]").forEach((dialog) => {
      if (dialog.dataset.initialized === "true") return;
      dialog.dataset.initialized = "true";

      const closeButton = dialog.querySelector("[data-completion-close]");
      closeButton.addEventListener("click", () => dialog.close());
      dialog.addEventListener("click", (event) => {
        if (event.target === dialog) dialog.close();
      });
      dialog.showModal();
    });

    document.querySelectorAll("[data-recommendation-picker]").forEach((picker) => {
      if (picker.dataset.initialized === "true") return;
      picker.dataset.initialized = "true";

      const dialog = picker.querySelector("[data-recommendation-dialog]");
      const openButton = picker.querySelector("[data-recommendation-open]");
      const closeButton = picker.querySelector("[data-recommendation-close]");
      const nextButton = picker.querySelector("[data-recommendation-next]");
      const chooseButton = picker.querySelector("[data-recommendation-choose]");
      const candidates = Array.from(picker.querySelectorAll("[data-recommendation-candidate]"));
      const pageSize = Number(picker.dataset.pageSize) || 5;
      const pageCount = Math.ceil(candidates.length / pageSize);
      let currentPage = 0;

      // 指定ページの候補だけを表示し、ページ切替時は選択を解除する。
      const showPage = (page) => {
        currentPage = page;
        candidates.forEach((candidate, index) => {
          candidate.hidden = Math.floor(index / pageSize) !== currentPage;
          candidate.querySelector("input[type=radio]").checked = false;
        });
        if (chooseButton) chooseButton.disabled = true;
      };

      // 開くたびに先頭の候補群へ戻してダイアログを表示する。
      openButton.addEventListener("click", () => {
        showPage(0);
        dialog.showModal();
      });

      // 閉じるボタン、またはダイアログの背景部分のクリックで閉じる。
      closeButton.addEventListener("click", () => dialog.close());

      dialog.addEventListener("click", (event) => {
        if (event.target === dialog) dialog.close();
      });

      // 5件ずつ次の候補へ進み、最後のページの次は先頭へ循環する。
      nextButton?.addEventListener("click", () => {
        if (pageCount > 0) showPage((currentPage + 1) % pageCount);
      });

      // 候補を選んだときだけ「これにする」を押せるようにする。
      candidates.forEach((candidate) => {
        candidate.querySelector("input[type=radio]").addEventListener("change", () => {
          if (chooseButton) chooseButton.disabled = false;
        });
      });

      // 初回表示も先頭ページだけに絞る。
      if (candidates.length > 0) showPage(0);
    });
  };

  // DOM構築後に初期化し、Turboによる画面遷移後も再度初期化する。
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initializeRecommendationPickers, { once: true });
  } else {
    initializeRecommendationPickers();
  }

  document.addEventListener("turbo:load", initializeRecommendationPickers);
})();