program p
implicit none
print *,dim(16777216.,16777215.),dim(16777216d0,16777215d0)
print *,log_gamma(-0.5),log_gamma(0.5),sign(-1.,-0.),sign(-1d0,-0d0)
end program
