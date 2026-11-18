program p
integer::a(3)=0
logical::m(3)=[.true.,.false.,.true.]
where(m)
m=.false.
a=1
elsewhere
a=2
end where
print *,a,m
end program
