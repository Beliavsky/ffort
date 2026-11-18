implicit none
character(*),parameter::a=merge("ab","cd",.true.),b=merge("ef","gh",.false.)
print '(a)',a,b
end
