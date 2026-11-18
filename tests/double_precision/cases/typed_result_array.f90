program p
implicit none
double precision::a(2)
a=values(2)
print *,kind(a),a
contains
function values(n) result(a)
integer,intent(in)::n
doubleprecision::a(n)
a=3.0d0
end function
end program
