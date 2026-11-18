program p
character(5)::a(4)=[character(5)::'a','bb','aa','b']
character(3)::s='aa '
print *,findloc(a(4:1:-1),trim(s)),findloc(a,trim(s),dim=1)
end program
