# Sample scene — 캐릭터 1명, 표정 이미지 3종, 대사 10줄 후 종료.

label sample:
    scene bg_classroom with dissolve

    "교실 창가에 오후 햇살이 비쳐든다."

    show yuna normal with dissolve

    yuna "안녕? 오늘 수업 어땠어?"          # 1

    yuna "나는 수학이 너무 어려웠어."        # 2

    show yuna sad with dissolve

    yuna "시험 망한 것 같아서 걱정돼."       # 3

    yuna "열심히 했는데도 모르겠더라고."     # 4

    yuna "너는 잘 봤어?"                    # 5

    show yuna normal with dissolve

    yuna "그래도 오늘 하루는 즐거웠어."      # 6

    yuna "방과 후에 같이 공부할래?"          # 7

    show yuna happy with dissolve

    yuna "정말? 완전 좋아!"                 # 8

    yuna "도서관 2층에서 만나자."            # 9

    yuna "그럼 이따 봐!"                    # 10

    hide yuna with dissolve
    scene with fade

    "창밖으로 유나가 손을 흔들며 사라졌다."
    return
