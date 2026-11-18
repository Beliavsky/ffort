program p
implicit none
integer::double(2),doubleprecision(2),precision(2)
double(1)=1
double(2)=2
doubleprecision(1)=3
doubleprecision(2)=4
precision=double+doubleprecision
print *,precision
end program
