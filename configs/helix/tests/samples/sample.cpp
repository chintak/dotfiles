// Parity sample for C++.
#include <iostream>
#include <memory>
#include <string>
#include <vector>

namespace geo {

constexpr double kPi = 3.14159;

template <typename T>
class Shape {
public:
    explicit Shape(std::string name) : name_(std::move(name)) {}
    virtual ~Shape() = default;
    virtual T area() const = 0;
    const std::string& name() const noexcept { return name_; }

private:
    std::string name_;
};

class Circle final : public Shape<double> {
public:
    Circle(double r) : Shape("circle"), radius_(r) {}
    double area() const override { return kPi * radius_ * radius_; }

private:
    double radius_ = 1.0;
};

enum class Kind : int { Small, Large };

}  // namespace geo

using geo::Circle;

static auto total_area(const std::vector<std::unique_ptr<Circle>>& shapes) -> double {
    double sum = 0.0;
    for (const auto& s : shapes) {
        sum += s->area();
    }
    return sum;
}

int main(int argc, char* argv[]) {
    std::vector<std::unique_ptr<Circle>> shapes;
    shapes.push_back(std::make_unique<Circle>(2.0));
    auto big = [&shapes](double limit) -> bool {
        return total_area(shapes) > limit;
    };
    geo::Kind kind = big(10.0) ? geo::Kind::Large : geo::Kind::Small;
    if (kind == geo::Kind::Large && argc > 0 && argv != nullptr) {
        std::cout << "large\n" << static_cast<int>(kind) << std::endl;
    }
    bool flag = true;
    char c = 'x';
    try {
        throw std::runtime_error("boom");
    } catch (const std::exception& e) {
        std::cerr << e.what() << c << flag << '\n';
    }
    return 0;
}
