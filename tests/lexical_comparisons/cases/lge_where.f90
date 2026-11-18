program p
implicit none
character::a(3)
integer::x(3)
a=['a','b','c']
x=0
where(lge(a,'b'))
x=1
endwhere
print *,x
end program
