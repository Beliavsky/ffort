program p
implicit none
logical,parameter::a=.false..or..true.,b=a.and..false.,c=b.eqv..false.
print *,a,b,c
end program p
