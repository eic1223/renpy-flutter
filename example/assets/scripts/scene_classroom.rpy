# Scene 1 — 교실의 유나
# 캐릭터: 유나 (yuna), 표정: normal / happy / sad, 대사 10줄

label classroom:
    scene bg_classroom with dissolve

    "방과 후 교실. 오후 햇살이 창문을 통해 비스듬히 들어온다."

    show yuna normal with dissolve

    yuna "어, 아직 안 갔어? 나도 막 정리하려던 참이었는데."      # 1

    yuna "오늘 수학 시험... 나 완전 망한 것 같아."               # 2

    show yuna sad with dissolve

    yuna "3번 문제에서 막혔는데 결국 못 풀었어."                 # 3

    yuna "열심히 공부했는데도 이러니까 진짜 자신감이 없어."      # 4

    yuna "너는 잘 봤어? 솔직하게 말해도 돼."                    # 5

    show yuna normal with dissolve

    yuna "그렇구나... 역시 넌 다르다."                          # 6

    yuna "나도 다음엔 더 일찍부터 준비해야겠다."                 # 7

    show yuna happy with dissolve

    yuna "그나저나 오늘 도서관 같이 갈래? 2층 조용한 자리 맡아놨어." # 8

    yuna "거기서 공부하면 집중 잘 되더라고."                    # 9

    yuna "같이 가면 더 열심히 할 수 있을 것 같아. 어때?"        # 10

    hide yuna with dissolve
    scene with fade

    "창밖으로 넘어가는 노을을 뒤로, 유나가 먼저 문을 나섰다."
    return
