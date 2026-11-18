program p
implicit none
character(4)::a(5)=[character(4)::'aa','b','aa ','aa x','']
print *,findloc(a,'aa'),findloc(a,'aa  ',1,back=.true.),findloc(a,'')
print *,findloc(a,'aa x '),findloc(a,'xxxxx')
end program
