program p
implicit none
integer::double,precision,doubleprecision
integer::items(2)
double=1
precision=2
doubleprecision=3
items=[double,precision]
call bump(double=double,precision=precision,doubleprecision=doubleprecision)
print *,double,precision,doubleprecision
contains
subroutine bump(double,precision,doubleprecision)
integer,intent(inout)::double,precision,doubleprecision
double=double+1
precision=precision+2
doubleprecision=doubleprecision+3
end subroutine
end program
