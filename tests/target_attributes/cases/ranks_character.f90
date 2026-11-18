program p
character(len=2),target::a(2),b(1,2),c(1,1,2)
a='xy';b='xy';c='xy'
print *,a(1)
print *,a(2)
print *,b(1,1)
print *,b(1,2)
print *,c(1,1,1)
print *,c(1,1,2)
end program
