import io

p = r"C:\Users\Administrator\Desktop\work\bsd45\RESUME-TASK.md"
t = io.open(p, encoding="utf-8", newline="").read().replace("\r\n", "\n")

start = t.index("## 7. S10 任务（下一步，按优先级）")
end = t.index("## 8. 提交与恢复")
s10 = t[start:end]
t = t[:start] + t[end:]

# renumber/rename the heading and drop the "next step" leftovers
s10 = s10.replace("## 7. S10 任务（下一步，按优先级）",
                  "## S10 任务（下次把仓库拉下来就从这里开始）", 1)
s10 = s10.replace("恢复方式：clone 仓库 → 按第 0 节构建 → 从第 7 节 S10.1 开始。",
                  "恢复方式：clone 仓库 → 按第 1 节构建 → 直接按上面的 S10.1 开始。")

anchor = "## 1. 任务目标（原始需求）"
t = t.replace(anchor, s10 + "\n" + anchor, 1)

# the recovery checklist should point at the new place
t = t.replace("从第 7 节 S10.1 开始", "从文档开头的 S10 节开始")
t = t.replace("按第 5 节构建", "按第 1 节环境或第 5 节构建")
t = t.replace("## 0. 在新机器上恢复（clone 仓库 → 继续 S10）",
              "## 0. 在新机器上恢复（clone 仓库 → 继续 S10）\n\n> S10 的完整任务定义在本文档最前面（标题下方第一个大节），\n> 打开文件往下滚几屏即可看到 4 个子任务与验收方式。\n", 1)

io.open(p, "w", encoding="utf-8", newline="\n").write(t)
print("moved S10 to the top; total lines:", len(t.splitlines()))
